# GeoDraw Interactive Features

## Overview
GeoDraw now includes three powerful ways to create geometric constructions:

1. **Interactive Tools** - Click and drag to create objects
2. **CLI Panel** - Type commands to create objects
3. **AI Panel** - Describe constructions in natural language

## Interactive Tools (Tool Palette)

The left sidebar provides visual tools for creating geometry:
- **Point Tool** - Click to create points
- **Line Tool** - Click two points to create a line
- **Circle Tool** - Click center then radius point to create a circle
- **Segment Tool** - Click two endpoints to create a line segment
- **More tools available...**

## CLI Panel (Command Line Interface)

Located in the **bottom-left** panel, the CLI allows you to type geometric commands directly.

### CLI Command Syntax

#### Creating Points
```
point A at 100 100
point B at 200 150
point C at 150 250
```

#### Creating Lines
```
line l1 through A B
line l2 through C perpendicular to l1
```

#### Creating Circles
```
circle c1 center A radius 50
circle c2 center B through C
```

#### Creating Segments
```
segment s1 from A to B
segment s2 from B to C
```

#### Construction Operations
```
intersect l1 l2 as P
midpoint A B as M
perpendicular l1 at P as l3
parallel l1 through B as l4
```

### CLI Features
- **Command History** - Use up/down arrows to recall previous commands
- **Auto-completion** - Suggestions as you type
- **Error Messages** - Clear feedback when commands are invalid
- **Object References** - Use created object names in subsequent commands

## AI Panel (Natural Language Interface)

Located in the **bottom-right** panel, the AI panel converts your natural language descriptions into geometric constructions.

### How to Use the AI Panel

1. **Describe** what you want to create in plain English
2. **Review** the generated CLI commands
3. **Validate** to check for errors
4. **Execute** to create the construction

### Example Prompts

#### Basic Shapes
```
Create an equilateral triangle with side length 100
Draw a square with side length 80
Make a regular pentagon centered at (200, 200)
```

#### Complex Constructions
```
Create a triangle ABC and construct its circumcircle
Draw a line and find a point on it, then construct a perpendicular
Create two intersecting circles and mark their intersection points
```

#### Step-by-Step Constructions
```
1. Create three non-collinear points A, B, and C
2. Connect them to form a triangle
3. Find the midpoint of each side
4. Draw the medians
5. Mark the centroid where the medians intersect
```

### AI Panel Features
- **Command Preview** - See the CLI commands before executing
- **Validation** - Automatic error checking
- **Step-by-Step Execution** - Watch constructions build incrementally
- **Explanation** - Understand what each command does

## Integration with Problem Management

All three methods (Tools, CLI, AI) work together:
- **Create Mode** - All panels available for new problems
- **Edit Mode** - All panels available to modify existing constructions
- **View Mode** - Canvas and Object Browser only (read-only)

### Saving Constructions
When you save a problem (click the Save button), the entire construction is encoded:
- All geometric objects (points, lines, circles, etc.)
- Dependency relationships (DAG structure)
- Visual styling and labels

### Loading Constructions
When you edit or view a problem, the construction is restored:
- All objects recreated in the DAG
- Dependencies maintained
- Ready for further editing (in Edit Mode)

## Object Browser (Right Panel)

Shows all geometric objects in your construction:
- **Hierarchy View** - See dependencies between objects
- **Selection** - Click to select objects on canvas
- **Properties** - View object properties and relationships

## Workflow Examples

### Example 1: Using Interactive Tools
1. Select Point tool from palette
2. Click on canvas to create points A, B, C
3. Select Line tool
4. Click A, then B to create line AB
5. Click B, then C to create line BC

### Example 2: Using CLI
1. Type in CLI panel: `point A at 100 100`
2. Type: `point B at 200 100`
3. Type: `circle c1 center A radius 50`
4. Type: `intersect c1 line through A B as P`

### Example 3: Using AI
1. In AI panel, type: "Create an isosceles triangle with base 100 and height 80"
2. Click "Generate Commands"
3. Review the generated CLI commands
4. Click "Execute" to create the construction

### Example 4: Combining Methods
1. Use AI to create initial shape: "Create a square ABCD with side 100"
2. Use CLI to add details: `circle c1 center A through B`
3. Use Tools to add finishing touches: Click to add more points interactively

## Tips for Effective Use

### When to Use Interactive Tools
- Quick sketching and exploration
- Visual, intuitive creation
- Fine-tuning object positions

### When to Use CLI
- Precise constructions with exact coordinates
- Repeating similar operations
- Scripting complex patterns
- When you know exact command syntax

### When to Use AI
- Learning geometric construction techniques
- Converting textbook problems to constructions
- Exploring different approaches
- When you're not sure of exact CLI syntax

## Configuration

### AI Service Setup
The AI panel requires an AI service backend. By default, it uses:
```dart
AIServiceConfig.development()
// Points to: http://localhost:3000/api/ai/generate-commands
```

For production, configure with your API endpoint:
```dart
AIServiceConfig.production(
  'https://your-api.com/generate-commands',
  'your-api-key'
)
```

### Customization
All panels can be:
- Resized (drag the dividers)
- Hidden (toggle visibility)
- Positioned (rearrange layout)

## Troubleshooting

### CLI Commands Not Working
- Check spelling of object names (case-sensitive)
- Ensure referenced objects exist
- Use Object Browser to see all available objects

### AI Not Generating Commands
- Check AI service is running
- Verify network connectivity
- Try simpler, more explicit descriptions
- Check browser console for errors

### Objects Not Appearing
- Check the Object Browser to verify objects were created
- Try zooming out (objects might be off-screen)
- Check CLI output for error messages

## Learn More

For detailed CLI command reference, see the geodraw package documentation:
- `packages/geodraw/lib/cli/command_parser.dart` - Command syntax
- `packages/geodraw/lib/cli/command_executor.dart` - Command implementations

For AI integration details:
- `packages/geodraw/lib/ai/ai_service.dart` - AI service configuration
- `packages/geodraw/lib/ai/command_validator.dart` - Validation logic
