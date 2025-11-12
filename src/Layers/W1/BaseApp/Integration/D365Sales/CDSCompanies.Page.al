// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

page 7214 "CDS Companies"
{
    Caption = 'Dataverse Companies', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    PageType = List;
    UsageCategory = None;
    Editable = false;
    SourceTable = "CDS Company";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(CompanyId; Rec.CompanyId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the company.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the company.';
                }
                field(ExternalId; Rec.ExternalId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the Dataverse company.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
            }
        }
    }
}
