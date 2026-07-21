// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

pageextension 10975 "FR Sales Order Comments" extends "Sales Order"
{
    actions
    {
        addlast("O&rder")
        {
            action(FRRegulatoryComments)
            {
                ApplicationArea = All;
                Caption = 'French Regulatory Comments';
                Image = ViewComments;
                RunObject = page "FR Regulatory Comments";
                RunPageLink = "Document Type" = const(Order), "Document No." = field("No.");
                ToolTip = 'View or edit regulatory comments for French electronic invoicing.';
            }
        }
    }
}

pageextension 10976 "FR Sales Invoice Comments" extends "Sales Invoice"
{
    actions
    {
        addlast(Processing)
        {
            action(FRRegulatoryComments)
            {
                ApplicationArea = All;
                Caption = 'French Regulatory Comments';
                Image = ViewComments;
                RunObject = page "FR Regulatory Comments";
                RunPageLink = "Document Type" = const(Invoice), "Document No." = field("No.");
                ToolTip = 'View or edit regulatory comments for French electronic invoicing.';
            }
        }
    }
}

pageextension 10977 "FR Sales CrMemo Comments" extends "Sales Credit Memo"
{
    actions
    {
        addlast(Processing)
        {
            action(FRRegulatoryComments)
            {
                ApplicationArea = All;
                Caption = 'French Regulatory Comments';
                Image = ViewComments;
                RunObject = page "FR Regulatory Comments";
                RunPageLink = "Document Type" = const("Credit Memo"), "Document No." = field("No.");
                ToolTip = 'View or edit regulatory comments for French electronic invoicing.';
            }
        }
    }
}

pageextension 10978 "FR Posted Sales Inv Comments" extends "Posted Sales Invoice"
{
    actions
    {
        addlast(Processing)
        {
            action(FRRegulatoryComments)
            {
                ApplicationArea = All;
                Caption = 'French Regulatory Comments';
                Image = ViewComments;
                RunObject = page "FR Regulatory Comments";
                RunPageLink = "Document Type" = const("Posted Invoice"), "Document No." = field("No.");
                RunPageMode = View;
                ToolTip = 'View the regulatory comments included in French electronic invoices.';
            }
        }
    }
}

pageextension 10979 "FR Posted Sales CrMemo Comm" extends "Posted Sales Credit Memo"
{
    actions
    {
        addlast(Processing)
        {
            action(FRRegulatoryComments)
            {
                ApplicationArea = All;
                Caption = 'French Regulatory Comments';
                Image = ViewComments;
                RunObject = page "FR Regulatory Comments";
                RunPageLink = "Document Type" = const("Posted Credit Memo"), "Document No." = field("No.");
                RunPageMode = View;
                ToolTip = 'View the regulatory comments included in French electronic credit memos.';
            }
        }
    }
}