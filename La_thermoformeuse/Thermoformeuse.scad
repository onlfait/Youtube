// -----------------------------------------------------------------------------
// User settings
// -----------------------------------------------------------------------------
// Box size
boxWidth  = 200; // x
boxDepth  = 150; // y
boxHeight = 40;  // z

// Fingers width
fingersWidth = 8;

// Material thickness (fingers height)
materialThickness = 8;

// Corners margin (0 = materialThickness)
cornersMargin = 0;

// Grid holes
gridHolesRadius = 5;
gridHolesMargin = 5;

// Vacuum hole
// The diameter must be smaller than the (boxHeight + (2 * materialThickness))
vacuumHoleRadius = 5;
vacuumHoleX      = 0; // (0 = center)
vacuumHoleY      = 0; // (0 = center)

// Parts padding
partsPadding = 10;

// Output (1 = 2D, 2 = 3D)
output = 2;

// -----------------------------------------------------------------------------
// Internal settings
// -----------------------------------------------------------------------------
// Ensure good difference
diffOffset = 0.1;

// Grid cell size
gridCellSize = (gridHolesRadius * 2 + gridHolesMargin);

// Margings shortcuts
m1 = materialThickness;
m2 = m1 + (cornersMargin ? cornersMargin : m1);

// Faces definition
// A = x/z, B = y/z, C = x/y
// [width, height, xOffset, yOffset, oddX, oddY]
faceA = [boxWidth, boxHeight, m2, m1, true , false];
faceB = [boxDepth, boxHeight, m2, m1, true , true ];
faceC = [boxWidth, boxDepth , m2, m2, false, false];

// Debug (see your console)
echo(str("faceA = ", faceA));
echo(str("faceB = ", faceB));
echo(str("faceC = ", faceC));

// -----------------------------------------------------------------------------
// Get the odd number of fingers for a given length (force value > 0)
// -----------------------------------------------------------------------------
function getOddFingersNumber(w) =
    let(n = floor(w / fingersWidth), v = n % 2 ? n : n-1) v < 1 ? 1 : v;

// -----------------------------------------------------------------------------
// Draw a fingers pads line
// -----------------------------------------------------------------------------
module fingers(w, offset, odd = true) {
    // Get the number of fingers
    number = getOddFingersNumber(w);

    // Compute real fingers pad size
    width  = w / number;
    height = materialThickness + diffOffset;

    // Draw fingers pads
    if (offset && odd)
        translate([-diffOffset, 0, 0])
            square([offset + diffOffset, height]);

    translate([offset, 0, 0])
        for (i = [0:number-1])
            if ((i % 2 && odd) || (!(i % 2) && !odd))
                translate([i * width, 0, 0])
                    square([width, height]);

    if (offset && odd)
        translate([w + offset, 0, 0])
            square([offset + diffOffset, height]);
}

// -----------------------------------------------------------------------------
// Draw the provided face definition
// -----------------------------------------------------------------------------
module face2D(f) {
    w  = f[0];        // Face width
    h  = f[1];        // Face height
    x  = f[2];        // Fingers X offset
    y  = f[3];        // Fingers Y offset
    ox = f[4];        // Is X fingers odd
    oy = f[5];        // Is Y fingers odd
    uw = w - (x * 2); // Usinable width
    uh = h - (y * 2); // Usinable height

    difference() {
        // Base shape for the face
        square([w, h]);

        // Bottom fingers
        translate([0, -diffOffset, 0])
            fingers(uw, x, ox);

        // Top fingers
        translate([0, h-materialThickness, 0])
            fingers(uw, x, ox);

        rotate(90) {
            // Left fingers
            translate([0, -materialThickness, 0])
                fingers(uh, y, oy);

            // Right fingers
            translate([0, -w-diffOffset, 0])
                fingers(uh, y, oy);
        }
    }
}

// -----------------------------------------------------------------------------
// Faces shortcuts
// -----------------------------------------------------------------------------
module face(f, 3d = false) {
    if (3d) linear_extrude(materialThickness) face2D(f);
    else face2D(f);
}

module faceA(3d = false) face(faceA, 3d);
module faceB(3d = false) face(faceB, 3d);
module faceC(3d = false) face(faceC, 3d);

module frontSide(3d = false)  faceA(3d);
module backSide(3d = false)   faceA(3d);
module leftSide(3d = false)   faceB(3d);
module rightSide(3d = false)  faceB(3d);
module topSide(3d = false)    faceC(3d);
module bottomSide(3d = false) faceC(3d);

// -----------------------------------------------------------------------------
// Draw the holes grid
// -----------------------------------------------------------------------------
module hole(r, 3d = false) {
    translate([r, r, 0])
    if (3d) {
        translate([0, 0, -diffOffset])
            linear_extrude(materialThickness + (diffOffset * 2))
                circle(r, $fn=24);
    }
    else circle(r, $fn=24);
}

module holeLine(w, x, 3d = false) {
    for (i = [0:x-1])
        translate([i * gridCellSize, 0, 0])
            hole(gridHolesRadius, 3d);
}

module holesGrid(f, 3d = false) {
    w = f[0]; // Face width
    h = f[1]; // Face height

    // How many holes ?
    uw = w - (2 * materialThickness) - (2 * gridHolesMargin);
    uh = h - (2 * materialThickness) - (2 * gridHolesMargin);
    x  = floor((uw + gridHolesMargin) / gridCellSize);
    y  = floor((uh + gridHolesMargin) / gridCellSize);
    rw = (x * gridCellSize) - gridHolesMargin;
    rh = (y * gridCellSize) - gridHolesMargin;

    translate([(w / 2) - (rw / 2), (h / 2) - (rh / 2), 0])
        for (y = [0:y-1])
            translate([0, y * gridCellSize, 0])
                holeLine(w, x, 3d);
}

// Owerride the topSide shortcut
module topSide(3d = false) {
    difference() {
        faceC(3d);
        holesGrid(faceC, 3d);
    }
}

// -----------------------------------------------------------------------------
// Draw vacuum hole
// -----------------------------------------------------------------------------
module vacuumHole(3d = false) {
    x = vacuumHoleX ? vacuumHoleX + materialThickness : (faceA[0] / 2) - vacuumHoleRadius;
    y = vacuumHoleY ? vacuumHoleY + materialThickness : (faceA[1] / 2) - vacuumHoleRadius;;

    translate([x, y, 0])
        hole(vacuumHoleRadius, 3d);
}

// Owerride the frontSide shortcut
module frontSide(3d = false) {
    difference() {
        faceA(3d);
        vacuumHole(3d);
    }
}

// -----------------------------------------------------------------------------
// Draw 2D plates
// -----------------------------------------------------------------------------
module draw2D() {
    // Front side (A)
    frontSide();

    // Back side (A)
    translate([faceA[0] + faceB[0] + (partsPadding * 2), 0, 0])
        backSide();

    // Left side (B)
    translate([faceA[0] * 2 + faceB[0] + (partsPadding * 3), 0, 0])
        leftSide();

    // Right side (B)
    translate([faceA[0] + partsPadding, 0, 0])
        rightSide();

    // Top side (C)
    translate([0, faceA[1] + partsPadding, 0])
        topSide();

    // Bottom side (C)
    translate([0, -faceC[1] - partsPadding, 0])
        bottomSide();
}

// -----------------------------------------------------------------------------
// Draw 3D box
// -----------------------------------------------------------------------------
module draw3D() {
    // Front side (A)
    translate([0, materialThickness, 0])
        rotate([90, 0, 0])
            color("SaddleBrown")
                frontSide(true);

    // Back side (A)
    translate([0, boxDepth, 0])
        rotate([90, 0, 0])
            color("SaddleBrown")
                backSide(true);

    // Left side (B)
    rotate([90, 0, 90])
        color("Chocolate")
            leftSide(true);

    // Right side (B)
    translate([boxWidth - materialThickness, 0, 0])
        rotate([90, 0, 90])
            color("Chocolate")
                rightSide(true);

    // Bottom side (C)
    color("Peru")
        bottomSide(true);

    // Top side (C)
    translate([0, 0, boxHeight - materialThickness])
        color("Peru")
            topSide(true);
}

// -----------------------------------------------------------------------------
// Draw the model
// -----------------------------------------------------------------------------
if (output == 1) draw2D();
if (output == 2) draw3D();
