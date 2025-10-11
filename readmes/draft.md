# GeoFrontApp - Interactive Geometry Application Specification

## Overview
GeoFrontApp is a GeoGebra-like interactive geometry application built with Flutter/Dart. The application features a visual geometry construction tool with an integrated theorem-proving solver that validates geometric constructions via API calls and presents solutions in a structured, pedagogical format.

---

## Project Workflow
This specification follows a structured development approach:
1. **Draft Enhancement** - Current phase of refining requirements
2. **Constitution** - Define core architecture and principles
3. **Specification** - Detailed technical specifications
4. **Planning** - Development roadmap and milestones
5. **Task Breakdown** - Granular implementation tasks
6. **Implementation** - Actual development phase

---

## Application Architecture

### High-Level Components
1. **GeoFrontApp** (Main Application)
   - Problem management and CRUD operations
   - Integration layer for solver API
   - Result presentation in pedagogical format

2. **GeoDraw Package** (Geometry Construction Engine)
   - Interactive geometry construction interface
   - Multiple construction input methods
   - Internal state management via DAG (Directed Acyclic Graph)

3. **GeoCalc Package** (Numerical Computation)
   - Internal representation of geometric objects
   - Multivector-based calculations
   - Coordinate and constraint management

4. **Solver API** (External Service)
   - Geometric theorem proving
   - Constraint validation
   - Construction verification

---

## State Management
**Framework:** Flutter BLoC Pattern (`flutter_bloc` package)
- All application state managed through BLoC architecture
- Clear separation of events, states, and business logic
- Reactive state updates throughout the application

---

## Core Features

### 1. Front Page - Problem Management (CRUD Interface)

#### Backend Integration
- **Storage:** Strapi CMS (port 1337)
- **API Communication:** GraphQL via `graphql_flutter`
- **State Management:** BLoC pattern for all CRUD operations

#### Features
- **List View:** Display all stored geometry problems
- **Read:** View problem details from listing
- **Delete:** Remove problems directly from listing
- **Create/Update:** Navigate to GeoDraw package for construction

#### BLoC Structure
```
Events:
- FetchProblems
- DeleteProblem
- NavigateToCreate
- NavigateToUpdate

States:
- ProblemsLoading
- ProblemsLoaded
- ProblemDeleted
- ProblemsError
```

---

### 2. GeoDraw Package - Interactive Geometry Tool

#### Core Functionality
- Single-problem focus (one problem at a time)
- Problems retrieved from Strapi backend
- Blank canvas for new problems
- Import existing problems via GeoDraw codec
- Full create and update capabilities

#### Three Construction Methods

##### A) Interactive Construction
- Icon-based tool selection (GeoGebra-style interface)
- Direct canvas manipulation
- Point-and-click geometry creation

##### B) Command-Line Interface (CLI)
- Text-based command input
- Example: `circle(p1, p2, p3)`
- Immediate construction execution
- Command history and autocomplete

##### C) Text-to-Construction (AI-Powered)
- Natural language input
- LLM processing via solver API
- Generates sequential command list
- Automatic construction execution

---

### 3. Solver Integration

#### Metadata Management
The application captures and stores:
- **Scalar Constraints:** Numerical relationships (distances, angles, ratios)
- **Object Constraints:** Geometric relationships (parallel, perpendicular, tangent)
- **Proof Goals:** What needs to be proven or verified

#### Solver Workflow
1. Construction + constraints sent to solver API
2. Solver returns success/failure status
3. On success: Step-by-step construction list received
4. Results displayed in pedagogical "bookish" format with:
   - Construction steps
   - Intermediate proofs
   - Explanatory text
   - Visual references

---

## GeoDraw Internal Architecture

### Object Hierarchy

#### Canvas Object System
```
CanvasObject (A) - Abstract base class
├─ draw() - abstract method
├─ GeometryObject (A)
│  ├─ SimpleGeometryObject (A)
│  │  └─ SimpleGeometryObjectList (A)
│  └─ ComplexGeometryObject (A)
│     └─ ComplexGeometryObjectList (A)
└─ [Text, Sliders, Annotations, etc.]

Legend: (A) = Abstract, (C) = Concrete
```

#### Simple Geometry Objects
**Definition:** Objects defined by a single equation
- Examples: Points, lines, circles
- Counter-example: Segments (require line + start/end points)

**Structure:**
- Single `Multivector` member representing the equation
- Abstract `SimpleGeometryObject` parent class
- Concrete implementations for specific types

#### Simple Geometry Object Lists
**Definition:** Collections of related simple objects
- Examples: 
  - Intersection points of two circles
  - Four tangent lines between two circles
- Each list item is a `SimpleGeometryObject`
- Each item contains its own `Multivector`

#### Complex Geometry Objects
**Definition:** Objects requiring a simple object plus boundary points
- Examples: Segments, arcs
- **Structure:** `Tuple(GeoPoint1, GeoPoint2, Multivector)`
  - `Multivector`: Defines the underlying simple object (line/circle)
  - `GeoPoint1`: Starting point (lies on the object)
  - `GeoPoint2`: Ending point (lies on the object)

#### Complex Geometry Object Lists
**Definition:** Collections forming composite shapes
- Examples:
  - Triangle: List of 3 segments
  - Rectangle: List of 4 segments with perpendicularity constraints
- Each element is a `ComplexGeometryObject`
- Maintains shape-level constraints

---

### Detailed Class Hierarchy

#### Simple Geometry Objects

```
SimpleGeometryObject (A)
│
├─ GeoPoint (A)
│  ├─ GeoPointer (C) - Free point
│  ├─ GeoMidpoint (C) - Midpoint between two points
│  └─ GeoInvPoint (C) - Inverted point
│
├─ GeoLine (A)
│  ├─ GeoLine2P (C) - Line through two points
│  ├─ GeoPerpendicularBisector (C) - Perpendicular bisector of segment
│  ├─ GeoPerpendicularLine (C) - Perpendicular to line through point
│  ├─ GeoParallelLine (C) - Parallel to line through point
│  ├─ GeoPolarLine (C) - Polar line with respect to circle
│  ├─ GeoInvLine (C) - Inverted line
│  └─ GeoAngleBisector (A)
│     └─ GeoAngleBisector3P (C) - Bisector of angle defined by 3 points
│
├─ GeoCircle (A)
│  ├─ GeoCircle2P (C) - Circle with center and point on circumference
│  ├─ GeoCircle3P (C) - Circle through three points
│  └─ GeoInvCircle (C) - Inverted circle
│
└─ GeoTrans (A) - Transformations
   ├─ GeoInverse (C) - Inversion transformation
   ├─ GeoRotate (C) - Rotation transformation
   └─ GeoDilate (C) - Dilation/scaling transformation
```

#### Simple Geometry Object Lists

```
SimpleGeometryObjectList (A)
│
├─ GeoPointList (A)
│  └─ GeoIntersection (C) - Intersection points of two objects
│
├─ GeoLineList (A)
│  ├─ GeoTangent (C) - Tangent lines to circle(s)
│  └─ GeoAngleBisector (A)
│     └─ GeoAngleBisector2L (C) - Bisectors of angles between two lines
│
└─ GeoCircleList (A)
   └─ [Future implementations]
```

#### Complex Geometry Objects

```
ComplexGeometryObject (A)
├─ GeoSegment (C) - Line segment
├─ GeoArc (C) - Circular arc
└─ GeoRay (C) - Ray (half-line)

ComplexGeometryObjectList (A)
├─ GeoPolygon (C) - General polygon
├─ GeoTriangle (C) - Triangle (3 segments)
├─ GeoRectangle (C) - Rectangle (4 segments + constraints)
└─ GeoRegularPolygon (C) - Regular n-gon
```

**Note:** `GeoPoint`, `GeoLine`, and `GeoCircle` have concrete `draw()` method implementations.

---

### DAG (Directed Acyclic Graph) Manager

#### Purpose
Manages the dependency graph of all canvas objects to ensure:
- Correct update propagation
- Efficient re-rendering
- Constraint satisfaction

#### Functionality

**Event Handling:**
- Processes BLoC events (tap, drag, tool selection)
- Proximity search across entire graph
- Object manipulation (move, resize, delete)

**Update Propagation:**
1. User interaction updates object's `Multivector`
2. Topological sort determines dependency order
3. Dependent objects updated top-down
4. Canvas re-rendered with updated states

**Dependency Management:**
- Maintains parent-child relationships
- Prevents circular dependencies
- Enables undo/redo functionality

---

### GeoCalc Package - Numerical Engine

#### Multivector Representation
**Core Class:** `Multivector`
- Geometric algebra representation of objects
- Unified coordinate system
- Efficient computation of:
  - Intersections
  - Distances
  - Angles
  - Transformations

#### Data Structure Mapping

**Simple Geometry Objects:**
- Single `Multivector` member
- Direct equation representation

**Simple Geometry Object Lists:**
- List of `SimpleGeometryObject`s
- Each with its own `Multivector`

**Complex Geometry Objects:**
- `Tuple(GeoPoint1, GeoPoint2, Multivector)`
- Boundary points + underlying object equation

**Complex Geometry Object Lists:**
- List of `ComplexGeometryObject`s
- Each with its own tuple structure

---

### Codec System

#### Purpose
Bidirectional conversion between:
- Internal DAG representation
- JSON format for storage/transmission

#### Functionality
- **Export:** DAG → JSON (for Strapi storage)
- **Import:** JSON → DAG (for problem loading)
- Preserves complete construction history
- Maintains all constraints and metadata

---

## User Interface Design

### Layout Structure

#### Landscape Mode
- **Left Panel:** Tool selection / CLI / AI input
- **Right Area:** Canvas for drawing

#### Portrait Mode
- **Bottom Panel:** Tool selection / CLI / AI input
- **Top Area:** Canvas for drawing

### Panel - Three Tabs

#### Tab 1: Interactive Tools
GeoGebra-style icon grid organized by categories:
- Movement & Basic Tools
- Point Tools
- Line/Segment/Ray Tools
- Polygon Tools
- Circle & Arc Tools
- Transformation Tools
- Measurement Tools
- etc.

#### Tab 2: Command-Line Interface
- Text input field
- Command history
- Syntax highlighting
- Autocomplete suggestions
- Example commands display

#### Tab 3: AI Construction
- Natural language text input
- "Generate Construction" button
- Progress indicator during LLM processing
- Preview of generated commands
- Execute or edit options

### Canvas Interface

#### Top Toolbar
- **Grid Toggle:** Show/hide coordinate grid
- **Clear Canvas:** Reset to blank state
- **View Toggle:** Switch between:
  - Geometry view (standard drawing)
  - Dependency tree view (DAG visualization)

#### Canvas Area
- Zoomable and pannable viewport
- Object selection via clicking
- Drag-and-drop manipulation
- Context menus for objects
- Snap-to-grid option
- Real-time constraint feedback

#### Sidebar/Object Browser
- List of all constructed objects
- Each object row shows:
  - Icon representing type
  - Label/name
  - Show/Hide toggle (eye icon)
  - Delete button (trash icon)
- Dependency tree structure (collapsible)
- Object properties panel (when selected)

---

## Construction Tools Catalog

### Movement / Basic Tools
- **Pan and Zoom:** Navigate canvas
- **Move Tool:** Reposition objects
- **Move around Point:** Constrained movement (desktop only)

### Point Tools
- **Free Point:** Unconstrained point placement
- **Point on Object:** Constrain point to line/circle/curve
- **Attach/Detach Point:** Toggle object constraints
- **Intersect:** Find intersection points automatically
- **Midpoint or Center:** Construct midpoint/center point

### Line / Segment / Ray / Vector Tools
- **Line (through two points):** Infinite line
- **Segment:** Bounded line between two points
- **Segment with Given Length:** Constrained length segment
- **Ray:** Half-line from origin point
- **Polyline:** Connected sequence of segments

### Special Lines / Auxiliary Lines
- **Perpendicular Line:** Perpendicular through point
- **Parallel Line:** Parallel through point
- **Perpendicular Bisector:** Bisector of segment
- **Angle Bisector:** Bisector of angle
- **Tangents:** Tangent lines to circle(s)
- **Polar or Diameter Line:** Polar with respect to circle
- **Best Fit Line:** Regression line through points
- **Locus Tool:** Trace path of dependent point

### Polygon Tools
- **Polygon:** General n-sided polygon
- **Regular Polygon:** Equal sides and angles
- **Rigid Polygon:** Maintains shape when dragged
- **Vector Polygon:** Polygon with vector properties

### Circle & Arc Tools
- **Circle with Center through Point:** Center + circumference point
- **Circle with Center and Radius:** Specified radius
- **Compass Tool:** Transfer distance as radius
- **Circle through 3 Points:** Circumcircle
- **Semicircle through 2 Points:** Half-circle
- **Circular Arc:** Arc with specified endpoints
- **Circumcircle Arc:** Arc through 3 points
- **Circle Sector:** Pie-slice region
- **Circumcircular Sector:** Sector through 3 points

### Conic Section Tools
- **Ellipse:** Standard ellipse construction
- **Hyperbola:** Standard hyperbola construction
- **Parabola:** Standard parabola construction
- **Conic through 5 Points:** General conic section

### Measurement / Annotation Tools
- **Angle:** Measure and display angle
- **Angle with Given Size:** Construct specific angle
- **Distance or Length:** Measure between points/on objects
- **Area:** Calculate and display area
- **Slope:** Display slope of line
- **Create List:** Group objects for batch operations

### Transformation Tools
- **Reflect about Line:** Mirror reflection
- **Reflect about Point:** Point reflection
- **Reflect about Circle:** Inversion in circle
- **Rotate around Point:** Rotation transformation
- **Translate by Vector:** Vector translation
- **Dilate (Scale) from Point:** Scaling transformation

### Special / Other Object Tools
- **Text:** Add text annotations
- **Image:** Insert image onto canvas
- **Pen / Freehand Shape:** Draw custom shapes
- **Relation Tool:** Define custom relationships
- **Function Inspector:** Analyze functions

### Action / Interactive Tools
- **Slider:** Number slider for parameters
- **Check Box:** Boolean toggle control
- **Button (with script):** Custom scripted actions
- **Input Box:** Dynamic value input

### General / Utility Tools
- **Translate View:** Pan the graphics view
- **Zoom In / Zoom Out:** Scale viewport
- **Show / Hide Object:** Toggle visibility
- **Show / Hide Label:** Toggle label visibility
- **Copy Visual Style:** Apply styling to other objects
- **Delete Tool:** Remove objects

---

## Command-Line Interface (CLI)

### Command Syntax
Commands follow functional notation:
```
circle(p1, p2, p3)           // Circle through 3 points
line(A, B)                   // Line through points A and B
perpendicular(L1, P1)        // Perpendicular to L1 through P1
midpoint(A, B)               // Midpoint of AB
intersect(L1, C1)            // Intersection of line and circle
```

### CLI Features
- **Command History:** Up/down arrow navigation
- **Autocomplete:** Tab completion for commands
- **Variable Assignment:** `p1 = point(0, 0)`
- **Chained Commands:** Multiple commands in sequence
- **Error Feedback:** Immediate syntax/constraint errors
- **Command Reference:** Built-in help system

### Toggle Mode
CLI behavior changes based on construction mode:
- **Direct Mode:** Immediate execution and rendering
- **Script Mode:** Build command sequence before execution
- **AI Mode:** Commands generated by LLM, reviewed before execution

---

## AI-Powered Construction

### Natural Language Processing Flow
1. User enters description in natural language
   - Example: "Draw an equilateral triangle with side length 5"
2. Text sent to solver API
3. API forwards to LLM service
4. LLM returns sequential command list:
   ```
   p1 = point(0, 0)
   p2 = point(5, 0)
   p3 = rotate(p2, p1, 60°)
   triangle(p1, p2, p3)
   ```
5. Commands displayed for user review
6. User can:
   - Execute all commands
   - Edit individual commands
   - Cancel and retry with modified description

### Supported Language Patterns
- Imperative: "Draw a circle tangent to two lines"
- Descriptive: "An isosceles triangle with base 6 and height 4"
- Relational: "Two parallel lines 3 units apart"
- Complex: "A square inscribed in a circle of radius 5"

---

## Solver System

### Input to Solver
The application sends to the solver API:
1. **Construction Sequence:** Complete list of commands that built the figure
2. **Scalar Constraints:** 
   - `distance(A, B) = 5`
   - `angle(BAC) = 60°`
   - `ratio(AB, CD) = 2:3`
3. **Object Constraints:**
   - `parallel(L1, L2)`
   - `perpendicular(L3, L4)`
   - `tangent(C1, L5)`
4. **Proof Goals:**
   - "Prove: Triangle ABC is equilateral"
   - "Show: Lines L1 and L2 are perpendicular"
   - "Verify: Point P lies on circle C"

### Solver Output

#### On Success
Returns structured proof with:
1. **Status:** `success: true`
2. **Construction Steps:** 
   - Each step with attached explanation
   - Intermediate lemmas and theorems applied
   - Visual references to diagram elements
3. **Proof Narrative:** Human-readable logical flow
4. **Verification:** Constraint satisfaction confirmation

#### On Failure
Returns:
1. **Status:** `success: false`
2. **Error Type:** 
   - Under-constrained
   - Over-constrained
   - Contradictory constraints
   - Invalid construction
3. **Diagnostic Information:**
   - Which constraints failed
   - Suggestions for corrections
   - Alternative approaches

### Bookish Presentation
Results displayed in textbook-style format:
- **Title:** Problem statement
- **Given:** Known information with diagram references
- **Prove/Show:** Goal statement
- **Construction:** Numbered steps with miniature diagrams
- **Proof:** Logical argument with theorem citations
- **Conclusion:** Summary statement
- **Q.E.D. symbol:** Visual completion indicator

---

## Technical Stack Summary

### Frontend
- **Framework:** Flutter/Dart
- **State Management:** `flutter_bloc`
- **GraphQL Client:** `graphql_flutter`
- **Canvas Rendering:** Custom painters with Flutter Canvas API

### Backend
- **CMS:** Strapi (port 1337)
- **Database:** (Strapi default - PostgreSQL/MySQL)
- **API:** GraphQL endpoints

### Solver Service
- **API:** RESTful or GraphQL endpoints
- **LLM Integration:** External service for text-to-commands
- **Theorem Prover:** Custom or integrated proving engine

### Packages Structure
```
geofrontapp/
├─ lib/
│  ├─ blocs/           // BLoC state management
│  ├─ models/          // Data models
│  ├─ screens/         // UI screens
│  ├─ services/        // API services
│  └─ widgets/         // Reusable widgets
├─ packages/
│  ├─ geodraw/         // Geometry construction engine
│  │  ├─ lib/
│  │  │  ├─ models/    // Geometry object classes
│  │  │  ├─ dag/       // DAG manager
│  │  │  ├─ codec/     // JSON serialization
│  │  │  ├─ tools/     // Construction tools
│  │  │  └─ ui/        // GeoDraw widgets
│  └─ geocalc/         // Numerical computation
│     └─ lib/
│        ├─ multivector.dart
│        └─ calculations.dart
```

---

## Next Steps

After approval of this enhanced draft, we will proceed with:

1. **/constitution** - Define architectural principles and design patterns
2. **/specify** - Create detailed technical specifications for each component
3. **/plan** - Develop implementation roadmap with milestones
4. **/tasks** - Break down into granular development tasks
5. **/implement** - Begin actual development

Please review this enhanced specification and provide feedback before we proceed to the constitution phase.