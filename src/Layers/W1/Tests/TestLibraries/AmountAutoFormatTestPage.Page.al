page 132583 "Amount Auto Format Test Page"
{
    SourceTable = "Amount Auto Format Test Table";

    layout
    {
        area(content)
        {
            // case 1
            field("Case1GLSetup1"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case1GLSetup1Expression;
                AutoFormatType = 1;
            }
            field("Case1GLSetup2"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case1GLSetup2Expression;
                AutoFormatType = 1;
            }
            field("Case1Currency"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case1CurrencyExpression;
                AutoFormatType = 1;
            }
            // case 2
            field("Case2GLSetup1"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case2GLSetup1Expression;
                AutoFormatType = 2;
            }
            field("Case2GLSetup2"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case2GLSetup2Expression;
                AutoFormatType = 2;
            }
            field("Case2Currency"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case2CurrencyExpression;
                AutoFormatType = 2;
            }
            // case 10
            field("Case10NoFormatSubtype"; Amount)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case10NoFormatSubtypeExpression;
                AutoFormatType = 10;
            }
            field("Case10GLSetup1"; Case10GLSetup1)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case10GLSetup1Expression;
                AutoFormatType = 10;
            }
            field("Case10GLSetup2"; Case10GLSetup2)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case10GLSetup2Expression;
                AutoFormatType = 10;
            }
            field("Case10Currency1"; Case10Currency1)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case10Currency1Expression;
                AutoFormatType = 10;
            }
            field("Case10Currency2"; Case10Currency2)
            {
                ApplicationArea = All;
                AutoFormatExpression = Case10Currency2Expression;
                AutoFormatType = 10;
            }
        }
    }

    var
        Amount: Decimal;
        // case 1
        Case1GLSetup1Expression: Text[80];
        Case1GLSetup2Expression: Text[80];
        Case1CurrencyExpression: Text[80];
        // case 2
        Case2GLSetup1Expression: Text[80];
        Case2GLSetup2Expression: Text[80];
        Case2CurrencyExpression: Text[80];
        // case 10
        Case10NoFormatSubtypeExpression: Text[80];
        Case10GLSetup1Expression: Text[80];
        Case10GLSetup2Expression: Text[80];
        Case10Currency1Expression: Text[80];
        Case10Currency2Expression: Text[80];

    procedure setAutoFormatExpressionCase1(Expr1: Text[80]; Expr2: Text[80]; Expr3: Text[80])
    begin
        Case1GLSetup1Expression := Expr1;
        Case1GLSetup2Expression := Expr2;
        Case1CurrencyExpression := Expr3;
    end;

    procedure setAutoFormatExpressionCase2(Expr1: Text[80]; Expr2: Text[80]; Expr3: Text[80])
    begin
        Case2GLSetup1Expression := Expr1;
        Case2GLSetup2Expression := Expr2;
        Case2CurrencyExpression := Expr3;
    end;

    procedure setAutoFormatExpressionCase10(Expr1: Text[80]; Expr2: Text[80]; Expr3: Text[80]; Expr4: Text[80]; Expr5: Text[80])
    begin
        Case10NoFormatSubtypeExpression := Expr1;
        Case10GLSetup1Expression := Expr2;
        Case10GLSetup2Expression := Expr3;
        Case10Currency1Expression := Expr4;
        Case10Currency2Expression := Expr5;
    end;

    procedure InitializeExpression(RandomValue: Text[20])
    begin
        setAutoFormatExpressionCase1(RandomValue, RandomValue, RandomValue);
        setAutoFormatExpressionCase2(RandomValue, RandomValue, RandomValue);
        setAutoFormatExpressionCase10(RandomValue, RandomValue, RandomValue, RandomValue, RandomValue);
    end;
}