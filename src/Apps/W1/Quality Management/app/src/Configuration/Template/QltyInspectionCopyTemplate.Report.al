// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Copy/Duplicate an Existing Quality Inspection Template.
/// </summary>
report 20402 "Qlty. Inspection Copy Template"
{
    Caption = 'Copy Quality Inspection Template';
    ToolTip = 'Copy an Existing Quality Inspection Template.';
    ProcessingOnly = true;
    ApplicationArea = QualityManagement;
    AllowScheduling = false;

    dataset
    {
        dataitem(CurrentTemplate; "Qlty. Inspection Template Hdr.")
        {
            MaxIteration = 1;
            RequestFilterFields = Code, Description;
            RequestFilterHeading = 'Quality Inspection Template to copy from';

            trigger OnPreDataItem()
            begin
                if CurrentTemplate.Count() <> 1 then
                    Error(ASingleTemplateErr, CurrentTemplate.Count());
            end;

            trigger OnAfterGetRecord()
            begin
                if not CreateFromItems then
                    CopyTemplate(CurrentTemplate, TargetDestinationName, Description);
            end;
        }
        dataitem(CurrentItem; Item)
        {
            RequestFilterFields = "No.", Description, "Description 2", "Lot Nos.";
            DataItemTableView = sorting("No.") where("No." = filter(<> ''));
            RequestFilterHeading = 'Item numbers to use for creating template codes';

            trigger OnAfterGetRecord()
            begin
                if CreateFromItems then
                    CopyTemplateFromItem(CurrentTemplate, CurrentItem);
            end;

            trigger OnPreDataItem()
            begin
                if CreateFromItems and (CurrentItem.Count() > 0) then
                    if not Confirm(ThisWillReplaceTemplateConfigQst, false, CurrentItem.Count()) then
                        Error('');
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    Caption = 'General';

                    field(ChooseFromItems; CreateFromItems)
                    {
                        ApplicationArea = All;
                        Caption = 'Create from Item Nos.';
                        ToolTip = 'Specifies whether to create templates from items.';
                    }
                }
                group(NonItem)
                {
                    Caption = 'Code and Description for duplicating not based on an item';
                    InstructionalText = 'Use this with Create From Item Nos. turned off.';
                    Visible = not CreateFromItems;

                    field(ChooseTargetName; TargetDestinationName)
                    {
                        ApplicationArea = All;
                        Enabled = not CreateFromItems;
                        Caption = 'Target Code';
                        ToolTip = 'Specifies whether to name a specific template target';
                    }
                    field(ChooseTargetDescription; Description)
                    {
                        ApplicationArea = All;
                        Enabled = not CreateFromItems;
                        Caption = 'Target Description';
                        ToolTip = 'Specifies the description of the target template inspection';
                    }
                }
            }
        }
    }

    var
        CreateFromItems: Boolean;
        TargetDestinationName: Code[20];
        Description: Text[100];
        ThisWillReplaceTemplateConfigQst: Label 'This will duplicates the source template to %1 templates for %1 items.\\Target template names will use the item no. as their name.\\ If an existing template exists then template lines will be added, but will not be removed. Any removal of template lines must be done manually, or via a process such as a configuration package. \\ Do you want to proceed?', Comment = '%1=how many templates will be added/updated';
        ASingleTemplateErr: Label 'A single template must be chosen. The filters supplied result in %1 templates.', Comment = '%1=the expected number of templates';
        MustSpecifyACodeAndDescriptionErr: Label 'When using this report and not copying items you must specify a destination code and description.';

    local procedure CopyTemplateFromItem(CopyFromQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; Item: Record Item)
    var
        DescriptionToUse: Text[100];
    begin
        if CreateFromItems and (Item."No." <> '') then begin
            DescriptionToUse := CopyStr(Item.Description, 1, MaxStrLen(DescriptionToUse));
            if StrLen(DescriptionToUse) = 0 then
                DescriptionToUse := Item."No.";
            CopyTemplate(CopyFromQltyInspectionTemplateHdr, Item."No.", DescriptionToUse);
        end;
    end;

    local procedure CopyTemplate(CopyFromQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; SpecificTemplate: Code[20]; DescriptionToCopy: Text[100])
    var
        TargetQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        FromQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TargetQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        LastTemplateLineNo: Integer;
    begin
        if (SpecificTemplate <> '') and (DescriptionToCopy = '') and (CopyFromQltyInspectionTemplateHdr.Description <> '') then
            DescriptionToCopy := CopyFromQltyInspectionTemplateHdr.Description;

        if (SpecificTemplate = '') or (DescriptionToCopy = '') then
            Error(MustSpecifyACodeAndDescriptionErr);

        TargetQltyInspectionTemplateHdr := CopyFromQltyInspectionTemplateHdr;
        TargetQltyInspectionTemplateHdr.Code := SpecificTemplate;
        TargetQltyInspectionTemplateHdr.Description := DescriptionToCopy;
        TargetQltyInspectionTemplateHdr."Copied From Template Code" := CopyFromQltyInspectionTemplateHdr.Code;
        TargetQltyInspectionTemplateHdr.SetRecFilter();
        if not TargetQltyInspectionTemplateHdr.FindFirst() then
            TargetQltyInspectionTemplateHdr.Insert();

        FromQltyInspectionTemplateLine.Reset();
        FromQltyInspectionTemplateLine.SetRange("Template Code", CopyFromQltyInspectionTemplateHdr.Code);
        LastTemplateLineNo := 0;
        if FromQltyInspectionTemplateLine.FindLast() then
            LastTemplateLineNo := FromQltyInspectionTemplateLine."Line No.";

        if FromQltyInspectionTemplateLine.FindSet() then
            repeat
                Clear(TargetQltyInspectionTemplateLine);
                TargetQltyInspectionTemplateLine.Reset();
                TargetQltyInspectionTemplateLine := FromQltyInspectionTemplateLine;
                TargetQltyInspectionTemplateLine."Template Code" := TargetQltyInspectionTemplateHdr.Code;
                TargetQltyInspectionTemplateLine.SetRecFilter();
                TargetQltyInspectionTemplateLine.SetFilter("Test Code", '<>%1&<>''''', FromQltyInspectionTemplateLine."Test Code");
                if TargetQltyInspectionTemplateLine.FindFirst() then begin
                    LastTemplateLineNo += 10000;
                    TargetQltyInspectionTemplateLine := FromQltyInspectionTemplateLine;
                    TargetQltyInspectionTemplateLine."Template Code" := TargetQltyInspectionTemplateHdr.Code;
                    TargetQltyInspectionTemplateLine."Line No." := LastTemplateLineNo;
                    TargetQltyInspectionTemplateLine."Copied From Template Code" := CopyFromQltyInspectionTemplateHdr.Code;
                    TargetQltyInspectionTemplateLine.Insert();
                end else begin
                    TargetQltyInspectionTemplateLine.SetRange("Template Code", TargetQltyInspectionTemplateHdr.Code);
                    TargetQltyInspectionTemplateLine.SetRange("Test Code", FromQltyInspectionTemplateLine."Test Code");
                    TargetQltyInspectionTemplateLine.SetRange("Line No.", FromQltyInspectionTemplateLine."Line No.");
                    if not TargetQltyInspectionTemplateLine.FindFirst() then begin
                        TargetQltyInspectionTemplateLine := FromQltyInspectionTemplateLine;
                        TargetQltyInspectionTemplateLine."Template Code" := TargetQltyInspectionTemplateHdr.Code;
                        TargetQltyInspectionTemplateLine."Copied From Template Code" := CopyFromQltyInspectionTemplateHdr.Code;
                        TargetQltyInspectionTemplateLine.Insert();
                    end else begin
                        TargetQltyInspectionTemplateLine.TransferFields(FromQltyInspectionTemplateLine, false);
                        TargetQltyInspectionTemplateLine."Template Code" := TargetQltyInspectionTemplateHdr.Code;
                        TargetQltyInspectionTemplateLine."Copied From Template Code" := CopyFromQltyInspectionTemplateHdr.Code;
                        TargetQltyInspectionTemplateLine.Modify();
                    end;
                end;
                QltyResultConditionMgmt.CopyResultConditionsFromTemplateLineToTemplateLine(FromQltyInspectionTemplateLine, TargetQltyInspectionTemplateLine);
            until FromQltyInspectionTemplateLine.Next() = 0;
    end;
}
