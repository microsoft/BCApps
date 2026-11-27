// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10075 "IRS 1099 Doc. Suppl. API"
{
    APIPublisher = 'microsoft';
    APIGroup = 'irsForms';
    APIVersion = 'v1.0';
    EntityCaption = 'IRS 1099 Document Supplemental Line';
    EntitySetCaption = 'IRS 1099 Document Supplemental Lines';
    PageType = API;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    EntityName = 'irs1099documentsupplementalline';
    EntitySetName = 'irs1099documentsupplementallines';
    ODataKeyFields = SystemId;
    SourceTable = "IRS 1099 Doc. Suppl. Line";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId';
                }
                field(documentId; Rec."Document ID")
                {
                    Caption = 'Document ID';
                }
                field(supplementalBoxNo; Rec."Supplemental Box No.")
                {
                    Caption = 'Supplemental Box No.';
                }
                field(parentFormBoxNo; Rec."Parent Form Box No.")
                {
                    Caption = 'Parent Form Box No.';
                }
                field(valueType; Rec."Value Type")
                {
                    Caption = 'Value Type';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(occupationCode1; Rec."Occupation Code 1")
                {
                    Caption = 'Occupation Code 1';
                }
                field(occupationCode2; Rec."Occupation Code 2")
                {
                    Caption = 'Occupation Code 2';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
    end;
}
