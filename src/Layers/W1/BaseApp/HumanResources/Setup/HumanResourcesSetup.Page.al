// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Setup;

using Microsoft.HumanResources.Absence;

page 5233 "Human Resources Setup"
{
    AdditionalSearchTerms = 'personnel people employee staff hr setup';
    ApplicationArea = BasicHR;
    Caption = 'Human Resources Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Human Resources Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Employee Nos."; Rec."Employee Nos.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to employees.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the base unit of measure, such as hour or day.';
                }
                field("Automatically Create Resource"; Rec."Automatically Create Resource")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if a resource card is automatically created for an employee that is added to a project, service, or assembly activity.';
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Check Multiple Posting Groups"; Rec."Check Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
        area(navigation)
        {
            action("Human Res. Units of Measure")
            {
                ApplicationArea = BasicHR;
                Caption = 'Human Res. Units of Measure';
                Image = UnitOfMeasure;
                RunObject = Page "Human Res. Units of Measure";
                ToolTip = 'Set up the units of measure, such as DAY or HOUR, that you can select from in the Human Resources Setup window to define how employment time is recorded.';
            }
            action("Causes of Absence")
            {
                ApplicationArea = BasicHR;
                Caption = 'Causes of Absence';
                Image = AbsenceCategory;
                RunObject = Page "Causes of Absence";
                ToolTip = 'Set up reasons why an employee can be absent.';
            }
            action("Causes of Inactivity")
            {
                ApplicationArea = BasicHR;
                Caption = 'Causes of Inactivity';
                Image = InactivityDescription;
                RunObject = Page "Causes of Inactivity";
                ToolTip = 'Set up reasons why an employee can be inactive.';
            }
            action("Grounds for Termination")
            {
                ApplicationArea = BasicHR;
                Caption = 'Grounds for Termination';
                Image = TerminationDescription;
                RunObject = Page "Grounds for Termination";
                ToolTip = 'Set up reasons why an employment can be terminated.';
            }
            action(Unions)
            {
                ApplicationArea = BasicHR;
                Caption = 'Unions';
                Image = Union;
                RunObject = Page Unions;
                ToolTip = 'Set up different worker unions that employees may be members of, so that you can select it on the employee card.';
            }
            action("Employment Contracts")
            {
                ApplicationArea = BasicHR;
                Caption = 'Employment Contracts';
                Image = EmployeeAgreement;
                RunObject = Page "Employment Contracts";
                ToolTip = 'Set up the different types of contracts that employees can be employed under, such as Administration or Production.';
            }
            action(Relatives)
            {
                ApplicationArea = BasicHR;
                Caption = 'Relatives';
                Image = Relatives;
                RunObject = Page Relatives;
                ToolTip = 'Set up the types of relatives that you can select from on employee cards.';
            }
            action("Misc. Articles")
            {
                ApplicationArea = BasicHR;
                Caption = 'Misc. Articles';
                Image = Archive;
                RunObject = Page "Misc. Articles";
                ToolTip = 'Set up types of company assets that employees use, such as CAR or COMPUTER, that you can select from on employee cards.';
            }
            action(Confidential)
            {
                ApplicationArea = BasicHR;
                Caption = 'Confidential';
                Image = ConfidentialOverview;
                RunObject = Page Confidential;
                ToolTip = 'Set up types of confidential information, such as SALARY or INSURANCE, that you can select from on employee cards.';
            }
            action(Qualifications)
            {
                ApplicationArea = BasicHR;
                Caption = 'Qualifications';
                Image = QualificationOverview;
                RunObject = Page Qualifications;
                ToolTip = 'Set up types of qualifications, such as DESIGN or ACCOUNTANT, that you can select from on employee cards.';
            }
            action("Employee Statistics Groups")
            {
                ApplicationArea = BasicHR;
                Caption = 'Employee Statistics Groups';
                Image = StatisticsGroup;
                RunObject = Page "Employee Statistics Groups";
                ToolTip = 'Set up salary types, such as HOURLY or MONTHLY, that you use for statistical purposes.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Human Res. Units of Measure_Promoted"; "Human Res. Units of Measure")
                {
                }
                actionref("Causes of Absence_Promoted"; "Causes of Absence")
                {
                }
                actionref("Causes of Inactivity_Promoted"; "Causes of Inactivity")
                {
                }
                actionref("Grounds for Termination_Promoted"; "Grounds for Termination")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Employee', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Unions_Promoted; Unions)
                {
                }
                actionref(Relatives_Promoted; Relatives)
                {
                }
                actionref(Qualifications_Promoted; Qualifications)
                {
                }
                actionref("Employee Statistics Groups_Promoted"; "Employee Statistics Groups")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Documents', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Employment Contracts_Promoted"; "Employment Contracts")
                {
                }
                actionref("Misc. Articles_Promoted"; "Misc. Articles")
                {
                }
                actionref(Confidential_Promoted; Confidential)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

