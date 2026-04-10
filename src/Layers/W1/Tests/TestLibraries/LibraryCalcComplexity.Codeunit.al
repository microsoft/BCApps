codeunit 130010 "Library - Calc. Complexity"
{

    trigger OnRun()
    begin
    end;

    var
        DivisionByZeroErr: Label 'Division by zero.';

    procedure IsConstant(f1: Integer; f2: Integer): Boolean
    begin
        exit(f2 <= f1 * Noise());
    end;

    procedure IsLinear(x1: Decimal; x2: Decimal; x3: Decimal; f1: Decimal; f2: Decimal; f3: Decimal): Boolean
    var
        a: Decimal;
        b: Decimal;
        ExpectedF3: Decimal;
        ExpectedUpperBound: Decimal;
    begin
        // x1, x2, and x3 are sizes of data input. fx1, fx2, and fx3 are the cost of processing that data
        // If the cost is linear: f(x) = a.x + b
        // Demonstrate that the computational cost is linear by finding a and b and checking that
        // an upper bound can be defined, so fx3 is actually under the bound

        if x1 = x2 then
            Error(DivisionByZeroErr);

        a := (f1 - f2) / (x1 - x2);

        b := f1 - (a * x1);

        ExpectedF3 := (a * x3) + b;

        ExpectedUpperBound := ExpectedF3 * Noise();

        exit(f3 <= ExpectedUpperBound);
    end;

    procedure IsLogN(x1: Decimal; x2: Decimal; x3: Decimal; f1: Decimal; f2: Decimal; f3: Decimal): Boolean
    var
        a: Decimal;
        b: Decimal;
        ExpectedF3: Decimal;
        ExpectedUpperBound: Decimal;
    begin
        // x1, x2 and x3 are sizes of data input. fx1, fx2 and fx3 are the cost of processing that data
        // If the cost is logarithmic: f(x) = a.log(x) + b
        // Demonstrate that the computational cost is logarithmic by finding a and b and checking that
        // an upper bound can be defined, so that fx3 is actually under the bound

        if x1 = x2 then
            Error(DivisionByZeroErr);

        a := (f1 - f2) / (Log(x1) - Log(x2));
        b := f1 - a * Log(x1);

        ExpectedF3 := (a * Log(x3)) + b;

        ExpectedUpperBound := ExpectedF3 * Noise();

        exit(f3 <= ExpectedUpperBound);
    end;

    procedure IsNLogN(x1: Decimal; x2: Decimal; x3: Decimal; x4: Decimal; f1: Decimal; f2: Decimal; f3: Decimal; f4: Decimal): Boolean
    var
        a: Decimal;
        b: Decimal;
        c: Decimal;
        ExpectedF4: Decimal;
        ExpectedUpperBound: Decimal;
    begin
        // x1, x2, x3 and x4 are sizes of data input. fx1, fx2,fx3 and fx4 are the cost of processing that data
        // If the cost is quadratic: f(x) = a.x.log(x) + b.x + c
        // Demonstrate that the computational cost is quadratic by finding a and b and c and checking that
        // an upper bound can be defined, so fx4 is actually under the bound

        if (x1 = x2) or (x1 = x3) then
            Error(DivisionByZeroErr);

        b :=
          (((x1 * Log(x1) - x3 * Log(x3)) * (f1 - f2)) -
           ((x1 * Log(x1) - x2 * Log(x2)) * (f1 - f3))) /
          (((x1 - x2) * (x1 * Log(x1) - x3 * Log(x3))) -
           ((x1 - x3) * (x1 * Log(x1) - x2 * Log(x2))));

        a :=
          ((f1 - f2) - b * (x1 - x2)) /
          (x1 * Log(x1) - x2 * Log(x2));

        c := f1 - a * x1 * Log(x1) - b * x1;

        ExpectedF4 := (a * x4 * Log(x4)) + (b * x4) + c;

        ExpectedUpperBound := ExpectedF4 * Noise();

        exit(f4 <= ExpectedUpperBound);
    end;

    procedure IsQuadratic(x1: Decimal; x2: Decimal; x3: Decimal; x4: Decimal; f1: Decimal; f2: Decimal; f3: Decimal; f4: Decimal): Boolean
    var
        a: Decimal;
        b: Decimal;
        c: Decimal;
        ExpectedF4: Decimal;
        ExpectedUpperBound: Decimal;
    begin
        // x1, x2, x3 and x4 are sizes of data input. fx1, fx2,fx3 and fx4 are the cost of processing that data
        // If the cost is quadratic: f(x) = a.x.x + b.x + c
        // Demonstrate that the computational cost is quadratic by finding a and b and c and checking that
        // an upper bound can be defined, so fx4 is actually under the bound

        if (x1 = x2) or (x1 = x3) then
            Error(DivisionByZeroErr);

        b :=
          (((x1 * x1 - x3 * x3) * (f1 - f2)) -
           ((x1 * x1 - x2 * x2) * (f1 - f3))) /
          (((x1 - x2) * (x1 * x1 - x3 * x3)) -
           ((x1 - x3) * (x1 * x1 - x2 * x2)));

        a :=
          ((f1 - f2) - b * (x1 - x2)) /
          (x1 * x1 - x2 * x2);

        c := f1 - a * x1 * x1 - b * x1;

        ExpectedF4 := (a * x4 * x4) + (b * x4) + c;

        ExpectedUpperBound := ExpectedF4 * Noise();

        exit(f4 <= ExpectedUpperBound);
    end;

    local procedure Log(x: Decimal): Decimal
    var
        z: Decimal;
    begin
        // Deriving LogX base 2 from Taylor Series
        z := (x - 1) / (x + 1);
        z :=
          z +
          1 / 3 * Power(z, 3) +
          1 / 5 * Power(z, 5) +
          1 / 7 * Power(z, 7) +
          1 / 9 * Power(z, 9);
        z := 2 * z / 0.693147;
        exit(z);
    end;

    local procedure Noise(): Decimal
    begin
        exit(1.05); // Adding a 5% ceiling
    end;
}

