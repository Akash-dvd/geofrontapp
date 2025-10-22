export interface Env {
  SUPABASE_JWT_SECRET: string;
  SUPABASE_GRAPHQL_URL: string;
  SUPABASE_ANON_KEY: string;
  SOLVER_TUNNEL_URL: string;
  OPENAI_API_URL: string;
  OPENAI_API_KEY: string;
  OPENAI_MODEL?: string;
}

type JwtPayload = {
  sub: string;
  aud?: string | string[];
  exp?: number;
  iss?: string;
  role?: string;
  [key: string]: unknown;
};

const JSON_HEADERS = { 'content-type': 'application/json' } as const;

const handler = {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const pathname = normalizePath(url.pathname);

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: withCors({}, request.headers.get('Origin')),
      });
    }

    const origin = request.headers.get('Origin');

    if (pathname === '/graphql') {
      const authHeader = request.headers.get('Authorization');
      const token = extractBearer(authHeader);
      if (!token) {
        return unauthorized('Missing Supabase access token', origin);
      }

      const claims = await verifySupabaseJwt(token, env.SUPABASE_JWT_SECRET);
      if (!claims) {
        return unauthorized('Invalid or expired Supabase token', origin);
      }

      return forwardRequest(request, env.SUPABASE_GRAPHQL_URL, {
        Authorization: `Bearer ${token}`,
        'X-User-Id': claims.sub,
        apikey: env.SUPABASE_ANON_KEY,
      }, origin);
    }

    if (pathname === '/solver') {
      return forwardRequest(request, env.SOLVER_TUNNEL_URL, {}, origin);
    }

    if (pathname === '/llm') {
      return handleLlmRequest(request, env, origin);
    }

    return new Response('Not Found', {
      status: 404,
      headers: withCors(JSON_HEADERS, origin),
    });
  },
};

export default handler;

function normalizePath(pathname: string): string {
  return pathname.replace(/\/+$/, '').toLowerCase() || '/';
}

function withCors(headers: Record<string, string>, origin: string | null) {
  const result = new Headers(headers);
  if (origin) {
    result.set('Access-Control-Allow-Origin', origin);
  } else {
    result.set('Access-Control-Allow-Origin', '*');
  }
  result.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  result.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  result.set('Access-Control-Allow-Credentials', 'true');
  return result;
}

function unauthorized(message: string, origin: string | null) {
  return new Response(JSON.stringify({ error: message }), {
    status: 401,
    headers: withCors(JSON_HEADERS, origin),
  });
}

async function handleLlmRequest(request: Request, env: Env, origin: string | null) {
  if (request.method !== 'POST') {
    return new Response('Method Not Allowed', {
      status: 405,
      headers: withCors(JSON_HEADERS, origin),
    });
  }

  let payload: any;
  try {
    const rawBody = await request.text();
    payload = rawBody ? JSON.parse(rawBody) : {};
  } catch (error) {
    console.error('LLM request JSON parse error', error);
    return new Response(JSON.stringify({ error: 'Invalid JSON payload' }), {
      status: 400,
      headers: withCors(JSON_HEADERS, origin),
    });
  }

  const promptInput = typeof payload?.prompt === 'string' && payload.prompt.trim().length > 0
    ? payload.prompt.trim()
    : typeof payload?.description === 'string' && payload.description.trim().length > 0
        ? buildPromptFromDescription(payload.description.trim())
        : null;

  if (!promptInput) {
    return new Response(JSON.stringify({ error: 'Missing prompt or description' }), {
      status: 400,
      headers: withCors(JSON_HEADERS, origin),
    });
  }

  const model = env.OPENAI_MODEL ?? 'gpt-4o-mini';

  const openAIResponse = await fetch(env.OPENAI_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature: 0.1,
      messages: [
        {
          role: 'system',
          content:
            'You are a geometry construction assistant. Respond only with a JSON array of GeoDraw command strings. Do not include explanations.',
        },
        {
          role: 'user',
          content: promptInput,
        },
      ],
    }),
  });

  if (!openAIResponse.ok) {
    const errorBody = await openAIResponse.text();
    console.error('OpenAI error', openAIResponse.status, errorBody);
    return new Response(
      JSON.stringify({
        error: 'OpenAI request failed',
        status: openAIResponse.status,
      }),
      {
        status: 502,
        headers: withCors(JSON_HEADERS, origin),
      },
    );
  }

  let openAiJson: any;
  try {
    openAiJson = await openAIResponse.json();
  } catch (error) {
    console.error('Failed to decode OpenAI JSON', error);
    return new Response(JSON.stringify({ error: 'Invalid OpenAI response format' }), {
      status: 502,
      headers: withCors(JSON_HEADERS, origin),
    });
  }

  const content = openAiJson?.choices?.[0]?.message?.content;
  if (typeof content !== 'string') {
    return new Response(JSON.stringify({ error: 'OpenAI response missing content' }), {
      status: 502,
      headers: withCors(JSON_HEADERS, origin),
    });
  }

  const normalized = stripCodeFences(content.trim());

  let commands: string[];
  try {
    const parsed = JSON.parse(normalized);
    if (!Array.isArray(parsed)) {
      throw new Error('Response is not an array');
    }
    commands = parsed.map((value) => String(value));
  } catch (error) {
    console.error('Failed to parse commands JSON', error, normalized);
    return new Response(
      JSON.stringify({ error: 'OpenAI returned invalid JSON', content: normalized }),
      {
        status: 502,
        headers: withCors(JSON_HEADERS, origin),
      },
    );
  }

  return new Response(JSON.stringify({ commands }), {
    status: 200,
    headers: withCors(JSON_HEADERS, origin),
  });
}

function extractBearer(header: string | null): string | null {
  if (!header) return null;
  const parts = header.split(' ');
  if (parts.length !== 2) return null;
  return parts[0].toLowerCase() === 'bearer' ? parts[1] : null;
}

async function verifySupabaseJwt(token: string, secret: string): Promise<JwtPayload | null> {
  try {
    const [encodedHeader, encodedPayload, signature] = token.split('.');
    if (!encodedHeader || !encodedPayload || !signature) {
      return null;
    }

  const dataBuffer = new TextEncoder().encode(`${encodedHeader}.${encodedPayload}`).buffer;
  const signatureBuffer = decodeBase64Url(signature);

    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    const valid = await crypto.subtle.verify('HMAC', key, signatureBuffer, dataBuffer);
    if (!valid) {
      return null;
    }

  const payloadBytes = new Uint8Array(decodeBase64Url(encodedPayload));
    const payloadJson = new TextDecoder().decode(payloadBytes);
    const payload = JSON.parse(payloadJson) as JwtPayload;

    if (payload.exp && Date.now() >= payload.exp * 1000) {
      return null;
    }

    return payload;
  } catch (error) {
    console.error('JWT validation error', error);
    return null;
  }
}

async function forwardRequest(
  request: Request,
  targetUrl: string,
  extraHeaders: Record<string, string> = {},
  origin: string | null = null,
) {
  const headers = new Headers(request.headers);
  for (const [key, value] of Object.entries(extraHeaders)) {
    headers.set(key, value);
  }

  const init: RequestInit = {
    method: request.method,
    headers,
  };

  if (!['GET', 'HEAD'].includes(request.method.toUpperCase())) {
    init.body = await request.clone().arrayBuffer();
  }

  const response = await fetch(targetUrl, init);
  const corsHeaders = withCors({}, origin);
  response.headers.forEach((value, key) => {
    if (!corsHeaders.has(key)) {
      corsHeaders.set(key, value);
    }
  });

  return new Response(response.body, {
    status: response.status,
    headers: corsHeaders,
  });
}

function decodeBase64Url(segment: string): ArrayBuffer {
  const normalized = segment.replace(/-/g, '+').replace(/_/g, '/');
  const padLength = (4 - (normalized.length % 4)) % 4;
  const padded = normalized + '='.repeat(padLength);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function buildPromptFromDescription(description: string): string {
  return `You are a geometry construction assistant. Convert the following natural language description into a sequence of geometry commands.

Available commands:
- point(x, y, label): Create a free point at coordinates with label
- line(p1, p2, label): Create a line through two points
- segment(p1, p2, label): Create a segment between two points
- circle(center, point, label): Create a circle with center through point
- circle(center, radius, label): Create a circle with center and radius
- perpendicular(line, point, label): Create perpendicular line through point
- parallel(line, point, label): Create parallel line through point
- midpoint(p1, p2, label): Create midpoint between two points
- intersection(obj1, obj2, label): Find intersection points
- triangle(p1, p2, p3, label): Create triangle
- polygon(p1, p2, ..., pN, label): Create polygon
- regular(n, center, vertex, label): Create regular n-gon
- perpbisector(p1, p2, label): Perpendicular bisector of segment
- bisector(p1, vertex, p2, label): Angle bisector
- tangent(circle, point, label): Tangent from point to circle
- reflect(object, line, label): Reflect object about line
- rotate(object, center, angle, label): Rotate object about center
- dilate(object, center, factor, label): Scale object from center

Rules:
1. Generate valid command syntax following the format above
2. Use descriptive uppercase labels (A, B, C, etc. for points)
3. Include all intermediate construction steps
4. Order commands by dependencies (use objects only after they're created)
5. Return ONLY a JSON array of command strings, no explanation
6. Each command must be a valid string that can be parsed

User description: ${description}

Return format example: ["point(0, 0, A)", "point(5, 0, B)", "line(A, B, AB)"]

Return only the JSON array:`;
}

function stripCodeFences(content: string): string {
  if (!content.startsWith('```')) {
    return content;
  }
  return content
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
}
