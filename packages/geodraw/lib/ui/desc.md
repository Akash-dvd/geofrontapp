formal descriptor system

Let’s design a **taxonomy** similar to your existing “construction” layer — this time for:

* **Scalar Constraints** (numerical truths like distances, ratios, angles)
* **Object Constraints** (structural relations like collinearity, concurrency)
* **Scalar Proofs** (derived numeric equalities or proportions)
* **Object Proofs** (logical or relational derivations, e.g. proving perpendicularity)

---

## ⚙️ GEOMETRY PROVER DESCRIPTOR

### 🟩 I. **Scalar Constraints**

Scalar constraints define **numerical relationships** among geometric primitives.
They can be verified or used symbolically during proof construction.

| Constraint                         | Description                              |
| ---------------------------------- | ---------------------------------------- |
| **EqualLength(AB, CD)**            | Distance(AB) = Distance(CD)              |
| **FixedLength(AB, L)**             | Segment AB has a given constant length L |
| **EqualAngle(∠ABC, ∠DEF)**         | Two angles are equal                     |
| **FixedAngle(∠ABC, θ)**            | ∠ABC = θ                                 |
| **ProportionalLengths(AB, CD, r)** | AB / CD = r                              |
| **EqualArea(△ABC, △DEF)**          | Areas of triangles are equal             |
| **FixedArea(△ABC, A)**             | Area of triangle ABC = A                 |
| **EqualRadius(c₁, c₂)**            | Circles have equal radius                |
| **FixedRadius(c, r)**              | Circle c has radius r                    |
| **EqualSlope(l₁, l₂)**             | Lines have the same slope                |
| **FixedSlope(l, m)**               | Line l has fixed slope m                 |
| **EqualDistance(P, Q, R, S)**      | Distance(P, Q) = Distance(R, S)          |
| **FixedDistance(P, Q, d)**         | Distance(P, Q) = d                       |
| **EqualPerimeter(P₁…Pn, Q₁…Qm)**   | Perimeters of polygons equal             |
| **EqualCircumference(c₁, c₂)**     | Circumferences of circles equal          |

---

### 🟦 II. **Object Constraints**

Object constraints define **structural or positional relationships** between geometric entities.

| Constraint                     | Description                                       |
| ------------------------------ | ------------------------------------------------- |
| **AreCollinear(A, B, C)**      | Points A, B, C lie on one straight line           |
| **AreConcurrent(l₁, l₂, l₃)**  | Lines meet at a common point                      |
| **AreParallel(l₁, l₂)**        | Lines never intersect                             |
| **ArePerpendicular(l₁, l₂)**   | Lines intersect at 90°                            |
| **AreTangential(l, c)**        | Line l touches circle c at exactly one point      |
| **AreTangential(c₁, c₂)**      | Circles touch each other externally or internally |
| **AreConcentric(c₁, c₂)**      | Circles share the same center                     |
| **IsOnLine(P, l)**             | Point P lies on line l                            |
| **IsOnCircle(P, c)**           | Point P lies on circle c                          |
| **IsOnPolygon(P, poly)**       | Point P is on polygon perimeter                   |
| **IsInsidePolygon(P, poly)**   | Point P is inside polygon area                    |
| **IsOnArc(P, arc)**            | Point P lies on given arc                         |
| **IsReflection(P', P, l)**     | P′ is reflection of P across line l               |
| **IsInversion(P′, P, c)**      | P′ is inversion of P w.r.t. circle c              |
| **AreSimilar(△ABC, △DEF)**     | Triangles are similar                             |
| **AreCongruent(△ABC, △DEF)**   | Triangles are congruent                           |
| **AreSymmetric(O₁, O₂, axis)** | Objects are symmetric about given axis            |
| **AreCyclic(P₁…Pn)**           | Points lie on a common circle                     |
| **AreEquidistant(P₁…Pn, Q)**   | All Pᵢ are equidistant from Q                     |
| **IsBisector(l, ∠ABC)**        | Line l bisects angle ABC                          |

---

### 🟨 III. **Scalar Proof Goals**

Scalar proofs aim to show that a **numerical relation holds**, often as an equality or proportion derived from constraints.

| Proof Goal                           | Description                    |
| ------------------------------------ | ------------------------------ |
| **ProveEqualLength(AB, CD)**         | Show AB = CD                   |
| **ProveEqualAngle(∠ABC, ∠DEF)**      | Show angles equal              |
| **ProvePerpendicularity(l₁, l₂)**    | Show angle between lines = 90° |
| **ProveParallelism(l₁, l₂)**         | Show slopes equal              |
| **ProveRatio(AB, CD, r)**            | Show AB/CD = r                 |
| **ProveFixedDistance(P, Q, d)**      | Show PQ = d                    |
| **ProveEqualArea(△ABC, △DEF)**       | Show triangles have same area  |
| **ProveAreaRelation(△ABC, △DEF, k)** | Show area ratio = k            |
| **ProveCircleRadius(c, r)**          | Show circle c has radius r     |
| **ProveEqualSlope(l₁, l₂)**          | Show equal gradient            |

---

### 🟥 IV. **Object Proof Goals**

Object proofs assert **logical/structural conclusions** — like showing collinearity, concurrency, or tangency — derived from given premises.

| Proof Goal                          | Description                             |
| ----------------------------------- | --------------------------------------- |
| **ProveCollinear(A, B, C)**         | Show A, B, C are collinear              |
| **ProveConcurrent(l₁, l₂, l₃)**     | Show lines meet at one point            |
| **ProvePerpendicular(l₁, l₂)**      | Show l₁ ⟂ l₂                            |
| **ProveParallel(l₁, l₂)**           | Show l₁ ∥ l₂                            |
| **ProveOnCircle(P, c)**             | Show P lies on circle c                 |
| **ProveTangency(l, c)**             | Show line l tangent to circle c         |
| **ProveConcyclic(P₁, P₂, P₃, P₄)**  | Show points lie on one circle           |
| **ProveEquilateral(△ABC)**          | Show all sides equal                    |
| **ProveIsosceles(△ABC)**            | Show two sides equal                    |
| **ProveRectangle(P₁, P₂, P₃, P₄)**  | Show quadrilateral is rectangle         |
| **ProveSquare(P₁, P₂, P₃, P₄)**     | Show rectangle with equal sides         |
| **ProveRhombus(P₁, P₂, P₃, P₄)**    | Show all sides equal, opposite sides ∥  |
| **ProveCyclicQuadrilateral(P₁…P₄)** | Show quadrilateral is cyclic            |
| **ProvePolygonRegular(P₁…Pn)**      | Show polygon has equal sides and angles |

---

