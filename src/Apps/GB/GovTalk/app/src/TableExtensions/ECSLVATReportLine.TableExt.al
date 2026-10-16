// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.VAT.Reporting;

tableextension 10525 "ECSL VAT Report Line" extends "ECSL VAT Report Line"
{
    fields
    {
        modify("Report No.")
        {
            TableRelation = "VAT Report Header"."No.";
        }
#pragma warning disable AS0099 // Preserve the existing field ID for compatibility.
        field(10502; "Line Status GB"; Option)
        {
            CalcFormula = lookup("GovTalk Msg. Parts".Status where("Report No." = field("Report No."),
                                                                       "Part Id" = field("XML Part Id GB"),
                                                                       "VAT Report Config. Code" = const("EC Sales List")));
            Caption = 'Line Status';
            FieldClass = FlowField;
            OptionCaption = ' ,Released,Submitted,Accepted,Rejected';
            OptionMembers = " ",Released,Submitted,Accepted,Rejected;
        }
#pragma warning restore AS0099
        field(10503; "XML Part Id GB"; Guid)
        {
            Caption = 'XML Part Id';
            DataClassification = CustomerContent;
        }
    }
}