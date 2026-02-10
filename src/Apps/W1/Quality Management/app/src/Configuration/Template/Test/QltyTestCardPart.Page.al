// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// The all test part is a generic part to help with configuration of a quality inspection test.
/// </summary>
page 20437 "Qlty. Test Card Part"
{
    Caption = 'Test Details';
    PageType = CardPart;
    SourceTable = "Qlty. Test";
    LinksAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code)
            {
                AboutTitle = 'Code';
                AboutText = 'The short code to identify the test. You can enter a maximum of 20 characters, both numbers and letters.';
            }
            field(Description; Rec.Description)
            {
                AboutTitle = 'Description';
                AboutText = 'The friendly description for the Test. You can enter a maximum of 100 characters, both numbers and letters.';

            }
            field("Test Value Type"; Rec."Test Value Type")
            {
                AboutTitle = 'Test Value Type';
                AboutText = 'Specifies the data type of the values you can enter or select for this test. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';

                trigger OnValidate()
                begin
                    UpdateControlVisibilityState();
                    CurrPage.Update(true);
                end;
            }
            field("Default Value"; Rec."Default Value")
            {
                AboutTitle = 'Default Value';
                AboutText = 'A default value to set on the test.';

                trigger OnAssistEdit()
                begin
                    Rec.AssistEditDefaultValue();
                end;
            }
            field("Case Sensitive"; Rec."Case Sensitive")
            {
                AboutTitle = 'Case Sensitivity';
                AboutText = 'Choose if case sensitivity will be enabled for text based fields.';
            }
            field("Allowable Values"; Rec."Allowable Values")
            {
                Visible = ShowAllowableValues;
                AboutTitle = 'Allowable Values';
                AboutText = 'What the staff inspector can enter and the range of information they can put in. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your result conditions. If you had a result of Pass being 80 to 100, you would then configure 80..100 for that result.';

                trigger OnAssistEdit()
                begin
                    Rec.AssistEditAllowableValues();
                end;
            }
            group(SettingsForUOMWrapper)
            {
                Visible = IsNumber;
                Caption = ' ';
                ShowCaption = false;

                field(ChooseUOM; Rec."Unit of Measure Code")
                {
                    AboutTitle = 'Unit of Measure Code';
                    AboutText = 'Optionally enter the unit of measure for the field';
                }
            }
            group(SettingsForLookupWrapper)
            {
                Visible = IsLookup;
                Caption = ' ';
                ShowCaption = false;

                field("Lookup Table No."; Rec."Lookup Table No.")
                {
                    AboutTitle = 'Lookup Table No.';
                    AboutText = 'When using a table lookup as a data type then this defines which table you are looking up. For example, if you want to show a list of available reason codes from the reason code table then you would use table 231 "Reason Code" here.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditLookupTable();
                    end;
                }
                field("Lookup Table Name"; Rec."Lookup Table Caption")
                {
                    AboutTitle = 'Lookup Table No.';
                    AboutText = 'The name of the lookup table. When using a table lookup as a data type then this is the name of the table that you are looking up. For example, if you want to show a list of available reason codes from the reason code table then you would use table 231 "Reason Code" here.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditLookupTable();
                    end;
                }
                field("Lookup Field No."; Rec."Lookup Field No.")
                {
                    AboutTitle = 'Lookup Field No.';
                    AboutText = 'This is the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, then you could use from the "Reason Code" table field "1" which represents the field "Code" on that table. When someone is recording an inspection, and choosing the test value they would then see as options the values from this field.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditLookupField();
                    end;
                }
                field("Lookup Field Name"; Rec."Lookup Field Caption")
                {
                    AboutTitle = 'Lookup Field Name';
                    AboutText = 'This is the name of the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, and also were using field "1" as the Lookup Field (which represents the field "Code" on that table) then this would show "Code"';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditLookupField();
                    end;
                }
                field("Lookup Table Filter"; Rec."Lookup Table Filter")
                {
                    AboutTitle = 'Lookup Table Filter';
                    AboutText = 'This allows you to restrict which data are available from the Lookup Table by using a standard Business Central filter expression. For example if you were using table 231 "Reason Code" as your lookup table and wanted to restrict the options to codes that started with "R" then you could enter: where("Code"=filter(R*))';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditLookupTableFilter();
                    end;
                }
            }
        }
    }

    protected var
        IsLookup: Boolean;
        ShowAllowableValues: Boolean;
        IsNumber: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControlVisibilityState();
    end;

    procedure LoadExistingTest(CurrentTest: Code[20])
    begin
        if CurrentTest = '' then
            exit;

        if not Rec.Get(CurrentTest) then
            exit;

        Rec.SetRecFilter();
        UpdateControlVisibilityState();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Invoke this to update the control visibility state.
    /// </summary>
    procedure UpdateControlVisibilityState()
    begin
        IsLookup := Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Table Lookup";
        ShowAllowableValues := not (Rec."Test Value Type" in [
            Rec."Test Value Type"::"Value Type Table Lookup",
            Rec."Test Value Type"::"Value Type Boolean",
            Rec."Test Value Type"::"Value Type Text"]);
        IsNumber := Rec.IsNumericFieldType();
    end;
}
