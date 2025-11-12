// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

page 678 "IC Dimensions Setup"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Synchronization Setup';
    PageType = StandardDialog;
    SourceTable = "IC Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                ShowCaption = false;
                field(PartnerCode; Rec."Partner Code for Acc. Syn.")
                {
                    Caption = 'Partner Code';
                    ToolTip = 'Specifies the partner code with which you want to synchronize the intercompany dimensions.';
                    ApplicationArea = All;
                    Editable = true;
                    Enabled = true;
                }
            }
        }
    }

    trigger OnClosePage()
    var
        ICDimensions: Record "IC Dimension";
        ICPartner: Record "IC Partner";
        TempICPartnerDimension: Record "IC Dimension" temporary;
        ICMapping: Codeunit "IC Mapping";
        ICDataExchange: Interface "IC Data Exchange";
        MessageText: Text;
    begin
        if Rec."Partner Code for Acc. Syn." = '' then
            exit;

        if not ICPartner.Get(Rec."Partner Code for Acc. Syn.") then
            exit;

        ICDataExchange := ICPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerICDimension(ICPartner, TempICPartnerDimension);

        if TempICPartnerDimension.IsEmpty() then
            exit;

        if GuiAllowed() then begin
            MessageText := StrSubstNo(SyncronizeDimensionsQst, Rec."Partner Code for Acc. Syn.");
            if not ICDimensions.IsEmpty() then
                MessageText := StrSubstNo(SplitMessageTxt, MessageText, CleanExistingICDimensionsMsg);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, ContinueQst);
            if not Confirm(MessageText, false) then
                exit;
        end;

        ICMapping.SynchronizeDimensions(true, Rec."Partner Code for Acc. Syn.");
    end;

    var
        SplitMessageTxt: Label '%1\%2', Comment = '%1 = First part of the message, %2 = Second part of the message.', Locked = true;
        SyncronizeDimensionsQst: Label 'Partner %1 has intercompany dimensions that can be synchronized now.', Comment = '%1 = IC Partner code';
        CleanExistingICDimensionsMsg: Label 'Before synchronizing with a new partner it is necessary to delete existing intercompany dimensions.';
        ContinueQst: Label 'Do you want to continue?';
}
