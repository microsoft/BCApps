#pragma warning disable AA0247
page 17204 "Tax Register Line Subform"
{
    AutoSplitKey = true;
    Caption = 'Register Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Register Line Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax register line setup information.';
                }
                field("Check Exist Entry"; Rec."Check Exist Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check exist entry associated with the tax register line setup information.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount type associated with the tax register line setup information.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number associated with the tax register line setup information.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GLAcc.Reset();
                        if Rec."Account No." <> '' then begin
                            GLAcc.SetFilter("No.", Rec."Account No.");
                            if GLAcc.FindFirst() then;
                            GLAcc.SetRange("No.");
                        end;
                        if ACTION::LookupOK = PAGE.RunModal(0, GLAcc) then begin
                            Text := GLAcc."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        TaxRegisterName.Get(Rec."Section Code", Rec."Tax Register No.");
                        if TaxRegisterName."Table ID" = DATABASE::"Tax Register Item Entry" then
                            TaxRegisterName.FieldError("Table ID");
                        GLAcc.Reset();
                        if Rec."Bal. Account No." <> '' then begin
                            GLAcc.SetFilter("No.", Rec."Bal. Account No.");
                            if GLAcc.FindFirst() then;
                            GLAcc.SetRange("No.");
                        end;

                        if ACTION::LookupOK = PAGE.RunModal(0, GLAcc) then begin
                            Text := GLAcc."No.";
                            exit(true);
                        end;

                        exit(false);
                    end;
                }
                field(DimFilters; DimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions Filters';
                    Editable = false;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnAssistEdit()
                    begin
                        ShowDimensionsFilters();
                    end;
                }
                field(GLCorrDimFilters; GLCorrDimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Corr. Dimensions Filters';
                    Editable = false;
                    ToolTip = 'Specifies the dimensions by which data is shown.';

                    trigger OnAssistEdit()
                    begin
                        ShowGLCorrDimensionsFilters();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Dimensions Filters", "G/L Corr. Dimensions Filters");
        if Rec."Dimensions Filters" then
            DimFilters := Text1001
        else
            DimFilters := '';

        if Rec."G/L Corr. Dimensions Filters" then
            GLCorrDimFilters := Text1001
        else
            GLCorrDimFilters := '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        DimFilters := '';
        GLCorrDimFilters := '';
    end;

    var
        GLAcc: Record "G/L Account";
#pragma warning disable AA0074
        Text1001: Label 'Present';
#pragma warning restore AA0074
        TaxRegisterName: Record "Tax Register";
        DimFilters: Text[30];
        GLCorrDimFilters: Text[30];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label '%1 should be used for this type of tax register.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ShowDimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        CurrPage.SaveRecord();
        Commit();
        TaxRegisterName.Get(Rec."Section Code", Rec."Tax Register No.");
        if (TaxRegisterName."Table ID" <> DATABASE::"Tax Register G/L Entry") and (Rec."Line No." <> 0) then begin
            TaxRegDimFilter.FilterGroup(2);
            TaxRegDimFilter.SetRange("Section Code", Rec."Section Code");
            TaxRegDimFilter.SetRange("Tax Register No.", Rec."Tax Register No.");
            TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::"Entry Setup");
            TaxRegDimFilter.FilterGroup(0);
            TaxRegDimFilter.SetRange("Line No.", Rec."Line No.");
            PAGE.RunModal(0, TaxRegDimFilter);
        end else
            Error(Text1002, Rec.FieldCaption("G/L Corr. Dimensions Filters"));
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure ShowGLCorrDimensionsFilters()
    var
        TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
    begin
        CurrPage.SaveRecord();
        Commit();
        TaxRegisterName.Get(Rec."Section Code", Rec."Tax Register No.");
        if (TaxRegisterName."Table ID" = DATABASE::"Tax Register G/L Entry") and (Rec."Line No." <> 0) then begin
            TaxRegGLCorrDimFilter.FilterGroup(2);
            TaxRegGLCorrDimFilter.SetRange("Section Code", Rec."Section Code");
            TaxRegGLCorrDimFilter.SetRange("Tax Register No.", Rec."Tax Register No.");
            TaxRegGLCorrDimFilter.SetRange(Define, TaxRegGLCorrDimFilter.Define::"Entry Setup");
            TaxRegGLCorrDimFilter.SetRange("Line No.", Rec."Line No.");
            TaxRegGLCorrDimFilter.FilterGroup(0);
            PAGE.RunModal(0, TaxRegGLCorrDimFilter);
        end else
            Error(Text1002, Rec.FieldCaption("Dimensions Filters"));
        CurrPage.Update(false);
    end;
}

