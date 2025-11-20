// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5112 "Profile Question Details"
{
    Caption = 'Profile Question Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the profile question or answer.';
                }
                field("Multiple Answers"; Rec."Multiple Answers")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the question has more than one possible answer.';
                }
            }
            group(Classification)
            {
                Caption = 'Classification';
                field("Auto Contact Classification"; Rec."Auto Contact Classification")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the question is automatically answered when you run the Update Contact Classification batch job.';

                    trigger OnValidate()
                    begin
                        AutoContactClassificationOnAft();
                    end;
                }
                field("Customer Class. Field"; Rec."Customer Class. Field")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CustomerClassFieldEditable;
                    ToolTip = 'Specifies the customer information that the automatic classification is based on. There are seven options: Blank, Sales (LCY), Profit (LCY), Sales Frequency (Invoices/Year), Avg. Invoice Amount (LCY), Discount (%), and Avg. Overdue (Day).';

                    trigger OnValidate()
                    begin
                        CustomerClassFieldOnAfterValid();
                    end;
                }
                field("Vendor Class. Field"; Rec."Vendor Class. Field")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = VendorClassFieldEditable;
                    ToolTip = 'Specifies the vendor information that the automatic classification is based on. There are six options:';

                    trigger OnValidate()
                    begin
                        VendorClassFieldOnAfterValidat();
                    end;
                }
                field("Contact Class. Field"; Rec."Contact Class. Field")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = ContactClassFieldEditable;
                    ToolTip = 'Specifies the contact information on which the automatic classification is based. There are seven options:';

                    trigger OnValidate()
                    begin
                        ContactClassFieldOnAfterValida();
                    end;
                }
                field("Min. % Questions Answered"; Rec."Min. % Questions Answered")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = MinPctQuestionsAnsweredEditable;
                    HideValue = MinPctQuestionsAnsweredHideValue;
                    ToolTip = 'Specifies the number of questions in percentage that must be answered for this rating to be calculated.';
                }
                field("Starting Date Formula"; Rec."Starting Date Formula")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = StartingDateFormulaEditable;
                    ToolTip = 'Specifies the date to start the automatic classification of your contacts.';
                }
                field("Ending Date Formula"; Rec."Ending Date Formula")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = EndingDateFormulaEditable;
                    ToolTip = 'Specifies the date to stop the automatic classification of your contacts.';
                }
                field("Classification Method"; Rec."Classification Method")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = ClassificationMethodEditable;
                    ToolTip = 'Specifies the method you can use to classify contacts. There are four options: Blank, Defined Value, Percentage of Value and Percentage of Contacts.';

                    trigger OnValidate()
                    begin
                        ClassificationMethodOnAfterVal();
                    end;
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = SortingMethodEditable;
                    ToolTip = 'Specifies the sorting method for the automatic classification on which the question is based. This field is only valid when you select Percentage of Value or Percentage of Contacts in the Classification Method field. It indicates the direction of the percentage. There are two options:';
                }
                field("No. of Decimals"; Rec."No. of Decimals")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = NoOfDecimalsEditable;
                    HideValue = NoOfDecimalsHideValue;
                    ToolTip = 'Specifies the number of decimal places to use when entering values in the From Value and To Value fields.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AnswerValues)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Answer Points';
                Enabled = AnswerValuesEnable;
                Image = Answers;
                ToolTip = 'View or edit the number of points a questionnaire answer gives.';

                trigger OnAction()
                var
                    ProfileManagement: Codeunit ProfileManagement;
                begin
                    ProfileManagement.ShowAnswerPoints(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AnswerValues_Promoted; AnswerValues)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        MinPctQuestionsAnsweredHideValue := false;
        NoOfDecimalsHideValue := false;
        SetEditable();
        NoofDecimalsOnFormat();
        Min37QuestionsAnsweredOnFormat();
    end;

    trigger OnInit()
    begin
        AnswerValuesEnable := true;
        SortingMethodEditable := true;
        NoOfDecimalsEditable := true;
        EndingDateFormulaEditable := true;
        ClassificationMethodEditable := true;
        StartingDateFormulaEditable := true;
        MinPctQuestionsAnsweredEditable := true;
        ContactClassFieldEditable := true;
        VendorClassFieldEditable := true;
        CustomerClassFieldEditable := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange(Type, Rec.Type::Question);
    end;

    var
        NoOfDecimalsHideValue: Boolean;
        NoOfDecimalsEditable: Boolean;
        MinPctQuestionsAnsweredHideValue: Boolean;
        CustomerClassFieldEditable: Boolean;
        VendorClassFieldEditable: Boolean;
        ContactClassFieldEditable: Boolean;
        MinPctQuestionsAnsweredEditable: Boolean;
        StartingDateFormulaEditable: Boolean;
        ClassificationMethodEditable: Boolean;
        EndingDateFormulaEditable: Boolean;
        SortingMethodEditable: Boolean;
        AnswerValuesEnable: Boolean;

    procedure SetEditable()
    begin
        CustomerClassFieldEditable :=
          Rec."Auto Contact Classification" and (Rec."Vendor Class. Field" = Rec."Vendor Class. Field"::" ") and (Rec."Contact Class. Field" =
                                                                                                      Rec."Contact Class. Field"::" ");
        VendorClassFieldEditable :=
          Rec."Auto Contact Classification" and (Rec."Customer Class. Field" = Rec."Customer Class. Field"::" ") and (Rec."Contact Class. Field" =
                                                                                                          Rec."Contact Class. Field"::" ");
        ContactClassFieldEditable :=
          Rec."Auto Contact Classification" and (Rec."Customer Class. Field" = Rec."Customer Class. Field"::" ") and (Rec."Vendor Class. Field" =
                                                                                                          Rec."Vendor Class. Field"::" ");

        MinPctQuestionsAnsweredEditable := Rec."Contact Class. Field" = Rec."Contact Class. Field"::Rating;

        StartingDateFormulaEditable :=
          (Rec."Customer Class. Field" <> Rec."Customer Class. Field"::" ") or
          (Rec."Vendor Class. Field" <> Rec."Vendor Class. Field"::" ") or
          ((Rec."Contact Class. Field" <> Rec."Contact Class. Field"::" ") and (Rec."Contact Class. Field" <> Rec."Contact Class. Field"::Rating));

        EndingDateFormulaEditable := StartingDateFormulaEditable;

        ClassificationMethodEditable :=
          (Rec."Customer Class. Field" <> Rec."Customer Class. Field"::" ") or
          (Rec."Vendor Class. Field" <> Rec."Vendor Class. Field"::" ") or
          ((Rec."Contact Class. Field" <> Rec."Contact Class. Field"::" ") and (Rec."Contact Class. Field" <> Rec."Contact Class. Field"::Rating));

        SortingMethodEditable :=
          (Rec."Classification Method" = Rec."Classification Method"::"Percentage of Value") or
          (Rec."Classification Method" = Rec."Classification Method"
           ::"Percentage of Contacts");

        NoOfDecimalsEditable := ClassificationMethodEditable;

        AnswerValuesEnable := (Rec."Contact Class. Field" = Rec."Contact Class. Field"::Rating);
    end;

    local procedure AutoContactClassificationOnAft()
    begin
        SetEditable();
    end;

    local procedure CustomerClassFieldOnAfterValid()
    begin
        SetEditable();
    end;

    local procedure VendorClassFieldOnAfterValidat()
    begin
        SetEditable();
    end;

    local procedure ContactClassFieldOnAfterValida()
    begin
        SetEditable();
    end;

    local procedure ClassificationMethodOnAfterVal()
    begin
        SetEditable();
    end;

    local procedure NoofDecimalsOnFormat()
    begin
        if not NoOfDecimalsEditable then
            NoOfDecimalsHideValue := true;
    end;

    local procedure Min37QuestionsAnsweredOnFormat()
    begin
        if Rec."Contact Class. Field" <> Rec."Contact Class. Field"::Rating then
            MinPctQuestionsAnsweredHideValue := true;
    end;
}

