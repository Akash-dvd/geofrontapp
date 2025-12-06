# GeoDraw CLI Commands

This reference lists the geometry construction commands currently registered in the shared `CommandRegistry` and available via the CLI adapter (`packages/geodraw/lib/cli`).

- Command names are case-insensitive. Aliases resolve to the canonical command listed below.
- Geometry arguments accept either an object ID (e.g. `point_3`) or a label (e.g. `A`).
- String arguments must be wrapped in double quotes. Numeric arguments may be integers or decimals.

| Command | Aliases | Arguments | Description | Example |
| --- | --- | --- | --- | --- |
| `point(x, y)` | – | `x`, `y` – numeric coordinates | Creates a free point at the given coordinates. | `point(2.5, -1)` |
| `text(x, y, text?)` | – | `x`, `y` – numeric coordinates; `text` – optional string | Places a text annotation. If `text` is omitted, an auto label is generated. | `text(4, 6, "Altitude")` |
| `line(p1, p2)` | `segment`, `linesegment` | `p1`, `p2` – existing points | Creates the line through two points. | `line(A, B)` |
| `circle(center, point)` | – | `center` – point at center; `point` – point on circumference | Creates a circle through two points. | `circle(O, A)` |
| `circle3(p1, p2, p3)` | `circlethrough3`, `circumcircle` | `p1`, `p2`, `p3` – three non-collinear points | Creates the unique circle through three points. | `circle3(A, B, C)` |
| `midpoint(p1, p2)` | – | `p1`, `p2` – existing points | Creates the midpoint of a segment. | `midpoint(A, B)` |
| `perpendicular(line, point)` | `perp` | `line` – reference line; `point` – point the perpendicular should pass through | Creates a line perpendicular to the reference line. | `perpendicular(L1, C)` |
| `parallel(line, point)` | `para` | `line` – reference line; `point` – point the parallel should pass through | Creates a line parallel to the reference line. | `parallel(L1, D)` |
| `perpbisector(p1, p2)` | `perpbis` | `p1`, `p2` – points defining a segment | Creates the perpendicular bisector of the segment `p1p2`. | `perpbisector(A, B)` |
| `reflect(object, mirror, label?)` | – | `object` – point/line/circle/segment/arc/union; `mirror` – line, circle, point, or existing inverse transform (`GeoLineInverse`, `GeoCircleInverse`, `GeoPointInverse`); `label` – optional string | Reflects the object about the supplied mirror or transform. | `reflect(A, L1, A')` |
| `rotate(object, center, angle, label?)` | – | `object` – point/line/circle/segment/arc/union; `center` – rotation center point or existing `GeoRotate`; `angle` – rotation angle in degrees (omit when reusing a transform); `label` – optional string | Rotates the object about the center by the given degrees (counter-clockwise). | `rotate(B, O, 90, B1)` |
| `dilate(object, center, factor, label?)` | – | `object` – point/line/circle/segment/arc/union; `center` – dilation center point or existing `GeoDilate`; `factor` – scale factor (omit when reusing a transform); `label` – optional string | Scales the object from the center by the factor. | `dilate(Circ1, O, 1.5, Circ2)` |

## Not yet implemented

- `intersection(...)` – currently registered but returns an error when invoked.

If you add new geometry commands, update this file alongside the registry, tooling, and documentation work described in the project checklist.
