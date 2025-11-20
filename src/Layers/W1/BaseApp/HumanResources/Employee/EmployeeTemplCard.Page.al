// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Setup;

page 1388 "Employee Templ. Card"
{
    Caption = 'Employee Template';
    PageType = Card;
    SourceTable = "Employee Templ.";

    layout
    {
        area(Content)
        {
            group(Template)
            {
                Caption = 'Template';
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the template.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that will be used to assign numbers to employees.';
                }
            }
            group(General)
            {
                Caption = 'General';
                field(Gender; Rec.Gender)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s gender.';
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(Control13)
                {
                    ShowCaption = false;
                    field(City; Rec.City)
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = BasicHR;
                            ToolTip = 'Specifies the county of the employee.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field("Statistics Group Code"; Rec."Statistics Group Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a statistics group code to assign to the employee for statistical purposes.';
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Employee Posting Group"; Rec."Employee Posting Group")
                {
                    ApplicationArea = BasicHR;
                    LookupPageID = "Employee Posting Groups";
                    ToolTip = 'Specifies the employee''s type to link business transactions made for the employee with the appropriate account in the general ledger.';
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = IsAllowMultiplePostingGroupsVisible;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies how to apply payments to entries for this employee.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                RunObject = Page "Default Dimensions";
                RunPageLink = "Table ID" = const(1384),
                              "No." = field(Code);
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action(CopyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Template';
                Image = Copy;
                ToolTip = 'Copies all information to the current template from the selected one.';

                trigger OnAction()
                var
                    EmployeeTempl: Record "Employee Templ.";
                    EmployeeTemplList: Page "Employee Templ. List";
                begin
                    Rec.TestField(Code);
                    EmployeeTempl.SetFilter(Code, '<>%1', Rec.Code);
                    EmployeeTemplList.LookupMode(true);
                    EmployeeTemplList.SetTableView(EmployeeTempl);
                    if EmployeeTemplList.RunModal() = Action::LookupOK then begin
                        EmployeeTemplList.GetRecord(EmployeeTempl);
                        Rec.CopyFromTemplate(EmployeeTempl);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(CopyTemplate_Promoted; CopyTemplate)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        HumanResourcesSetup.Get();
        IsAllowMultiplePostingGroupsVisible := HumanResourcesSetup."Allow Multiple Posting Groups";
    end;

    var
        HumanResourcesSetup: Record "Human Resources Setup";
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        IsAllowMultiplePostingGroupsVisible: Boolean;
}
