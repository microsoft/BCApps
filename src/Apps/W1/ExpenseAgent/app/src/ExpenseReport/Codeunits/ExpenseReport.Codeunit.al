// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;

codeunit 6910 "Expense Report"
{
    Access = Internal;

    procedure GetExpenseReportLine(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer): Record "Expense Report Line"
    begin
        if (ExpenseReportNo <> ExpenseReportLine."Document No.") or (ExpenseReportLineNo <> ExpenseReportLine."Line No.") then
            if ExpenseReportLine.Get(ExpenseReportNo, ExpenseReportLineNo) then
                HasExpenseReportLine := true
            else
                Clear(ExpenseReportLine);

        exit(ExpenseReportLine);
    end;

    procedure GetHasExpenseReportLine(): Boolean
    begin
        exit(HasExpenseReportLine);
    end;

    procedure CopyPerDiemFromExpense(ExpenseNo: Code[20]; ReportNo: Code[20]; ReportLineNo: Integer)
    var
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpensePerDiem.SetRange("Expense No.", ExpenseNo);
        if ExpensePerDiem.FindSet() then
            repeat
                ExpenseReportLinePerDiem.Init();
                ExpenseReportLinePerDiem."Expense Report No." := ReportNo;
                ExpenseReportLinePerDiem."Expense Report Line No." := ReportLineNo;
                ExpenseReportLinePerDiem."Line No." := ExpensePerDiem."Line No.";
                ExpenseReportLinePerDiem."Expense No." := ExpensePerDiem."Expense No.";
                ExpenseReportLinePerDiem."Expense Category Code" := ExpensePerDiem."Expense Category Code";
                ExpenseReportLinePerDiem."Expense Subcategory Code" := ExpensePerDiem."Expense Subcategory Code";
                ExpenseReportLinePerDiem."Expense Location" := ExpensePerDiem."Expense Location";
                ExpenseReportLinePerDiem."Description" := ExpensePerDiem."Description";
                ExpenseReportLinePerDiem."Date" := ExpensePerDiem."Date";
                ExpenseReportLinePerDiem."Breakfast" := ExpensePerDiem."Breakfast";
                ExpenseReportLinePerDiem."Lunch" := ExpensePerDiem."Lunch";
                ExpenseReportLinePerDiem."Dinner" := ExpensePerDiem."Dinner";
                ExpenseReportLinePerDiem."Per Diem Amount" := ExpensePerDiem."Per Diem Amount";
                ExpenseReportLinePerDiem."Original Per Diem Amount" := ExpensePerDiem."Original Per Diem Amount";
                ExpenseReportLinePerDiem."Breakfast Reduction Percent" := ExpensePerDiem."Breakfast Reduction Percent";
                ExpenseReportLinePerDiem."Lunch Reduction Percent" := ExpensePerDiem."Lunch Reduction Percent";
                ExpenseReportLinePerDiem."Dinner Reduction Percent" := ExpensePerDiem."Dinner Reduction Percent";
                ExpenseReportLinePerDiem.Insert();
            until ExpensePerDiem.Next() = 0;
    end;

    procedure CopyItemizationFromExpense(ExpenseNo: Code[20]; ReportNo: Code[20]; ReportLineNo: Integer)
    var
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLineItem: Record "Expense Report Line Item";
    begin
        ExpenseItemization.SetRange("Expense No.", ExpenseNo);
        if ExpenseItemization.FindSet() then
            repeat
                ExpenseReportLineItem.Init();
                ExpenseReportLineItem."Expense Report No." := ReportNo;
                ExpenseReportLineItem."Expense Report Line No." := ReportLineNo;
                ExpenseReportLineItem."Line No." := ExpenseItemization."Line No.";
                ExpenseReportLineItem."Expense No." := ExpenseItemization."Expense No.";
                ExpenseReportLineItem."Expense Category Code" := ExpenseItemization."Expense Category Code";
                ExpenseReportLineItem."Expense Subcategory Code" := ExpenseItemization."Expense Subcategory Code";
                ExpenseReportLineItem."Description" := ExpenseItemization."Description";
                ExpenseReportLineItem."Start Date" := ExpenseItemization."Start Date";
                ExpenseReportLineItem."Daily Rate" := ExpenseItemization."Daily Rate";
                ExpenseReportLineItem."Quantity" := ExpenseItemization."Quantity";
                ExpenseReportLineItem."Amount" := ExpenseItemization."Amount";
                ExpenseReportLineItem.Refundable := ExpenseItemization.Refundable;
                ExpenseReportLineItem.Insert();
            until ExpenseItemization.Next() = 0;
    end;

    procedure CopyVATSpecificationFromExpense(ExpenseNo: Code[20]; ReportNo: Code[20]; ReportLineNo: Integer)
    var
        ExpenseVATSpecification: Record "Expense VAT Specification";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        ExpenseReportLine.Get(ReportNo, ReportLineNo);

        ExpenseVATSpecification.SetRange("Expense No.", ExpenseNo);
        if ExpenseVATSpecification.FindSet() then
            repeat
                ExpenseReportLineVATSpec.Init();
                ExpenseReportLineVATSpec."Document No." := ReportNo;
                ExpenseReportLineVATSpec."Document Line No." := ReportLineNo;
                ExpenseReportLineVATSpec."Line No." := ExpenseVATSpecification."Line No.";
                ExpenseReportLineVATSpec."Amount" := ExpenseVATSpecification."Amount";
                ExpenseReportLineVATSpec."VAT %" := ExpenseVATSpecification."VAT %";
                ExpenseReportLineVATSpec."VAT Amount" := ExpenseVATSpecification."VAT Amount";
                ExpenseReportLineVATSpec."VAT Base Amount" := ExpenseVATSpecification."VAT Base Amount";
                ExpenseReportLineVATSpec."VAT Prod. Posting Group" := ExpenseReportLine."VAT Prod. Posting Group";
                ExpenseReportLineVATSpec."VAT Bus. Posting Group" := ExpenseReportLine."VAT Bus. Posting Group";
                ExpenseReportLineVATSpec.Insert();
            until ExpenseVATSpecification.Next() = 0;
    end;

    procedure CopyParticipantsFromExpense(ExpenseNo: Code[20]; ReportNo: Code[20]; ReportLineNo: Integer)
    var
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
    begin
        ExpenseParticipant.SetRange("Expense No.", ExpenseNo);
        if ExpenseParticipant.FindSet() then
            repeat
                ExpenseReportLineParticipant.Init();
                ExpenseReportLineParticipant."Expense Report No." := ReportNo;
                ExpenseReportLineParticipant."Expense Report Line No." := ReportLineNo;
                ExpenseReportLineParticipant."Line No." := ExpenseParticipant."Line No.";
                ExpenseReportLineParticipant."Expense No." := ExpenseParticipant."Expense No.";
                ExpenseReportLineParticipant."Expense Category Code" := ExpenseParticipant."Expense Category Code";
                ExpenseReportLineParticipant."Expense Subcategory Code" := ExpenseParticipant."Expense Subcategory Code";
                ExpenseReportLineParticipant."Participant Type" := ExpenseParticipant."Participant Type";
                ExpenseReportLineParticipant."Participant Employee No." := ExpenseParticipant."Participant Employee No.";
                ExpenseReportLineParticipant."Participant Name" := ExpenseParticipant."Participant Name";
                ExpenseReportLineParticipant."Participant Organization" := ExpenseParticipant."Participant Organization";
                ExpenseReportLineParticipant."Participant Country/Region" := ExpenseParticipant."Participant Country/Region";
                ExpenseReportLineParticipant."Participant Title" := ExpenseParticipant."Participant Title";
                ExpenseReportLineParticipant."Participant Email" := ExpenseParticipant."Participant Email";
                ExpenseReportLineParticipant.Insert();
            until ExpenseParticipant.Next() = 0;
    end;

    procedure CopyReportLineParticipants(FromReportNo: Code[20]; FromLineNo: Integer; ToReportNo: Code[20]; ToLineNo: Integer)
    var
        SourceParticipant: Record "Expense Report Line Particip.";
        NewParticipant: Record "Expense Report Line Particip.";
    begin
        SourceParticipant.SetRange("Expense Report No.", FromReportNo);
        SourceParticipant.SetRange("Expense Report Line No.", FromLineNo);
        if SourceParticipant.FindSet() then
            repeat
                NewParticipant := SourceParticipant;
                NewParticipant."Expense Report No." := ToReportNo;
                NewParticipant."Expense Report Line No." := ToLineNo;
                NewParticipant.Insert();
            until SourceParticipant.Next() = 0;
    end;

    procedure CopyReportLineItemizations(FromReportNo: Code[20]; FromLineNo: Integer; ToReportNo: Code[20]; ToLineNo: Integer)
    var
        SourceItemization: Record "Expense Report Line Item";
        NewItemization: Record "Expense Report Line Item";
    begin
        SourceItemization.SetRange("Expense Report No.", FromReportNo);
        SourceItemization.SetRange("Expense Report Line No.", FromLineNo);
        if SourceItemization.FindSet() then
            repeat
                NewItemization := SourceItemization;
                NewItemization."Expense Report No." := ToReportNo;
                NewItemization."Expense Report Line No." := ToLineNo;
                NewItemization.Insert();
            until SourceItemization.Next() = 0;
    end;

    procedure CopyReportLinePerDiems(FromReportNo: Code[20]; FromLineNo: Integer; ToReportNo: Code[20]; ToLineNo: Integer)
    var
        SourcePerDiem: Record "Expense Report Line Per Diem";
        NewPerDiem: Record "Expense Report Line Per Diem";
    begin
        SourcePerDiem.SetRange("Expense Report No.", FromReportNo);
        SourcePerDiem.SetRange("Expense Report Line No.", FromLineNo);
        if SourcePerDiem.FindSet() then
            repeat
                NewPerDiem := SourcePerDiem;
                NewPerDiem."Expense Report No." := ToReportNo;
                NewPerDiem."Expense Report Line No." := ToLineNo;
                NewPerDiem.Insert();
            until SourcePerDiem.Next() = 0;
    end;

    procedure CopyReportLineComments(FromReportNo: Code[20]; FromLineNo: Integer; ToReportNo: Code[20]; ToLineNo: Integer)
    var
        SourceComment: Record "Expense Report Comment Line";
        NewComment: Record "Expense Report Comment Line";
    begin
        SourceComment.SetRange("Document Type", SourceComment."Document Type"::"Expense Report");
        SourceComment.SetRange("No.", FromReportNo);
        SourceComment.SetRange("Document Line No.", FromLineNo);
        if SourceComment.FindSet() then
            repeat
                NewComment := SourceComment;
                NewComment."No." := ToReportNo;
                NewComment."Document Line No." := ToLineNo;
                NewComment.Insert();
            until SourceComment.Next() = 0;
    end;

    procedure CopyReportLineAttachments(FromReportNo: Code[20]; FromLineNo: Integer; ToReportNo: Code[20]; ToLineNo: Integer)
    var
        SourceAttachment: Record "Document Attachment";
        NewAttachment: Record "Document Attachment";
    begin
        SourceAttachment.SetRange("Table ID", Database::"Expense Report Line");
        SourceAttachment.SetRange("No.", FromReportNo);
        SourceAttachment.SetRange("Line No.", FromLineNo);
        if SourceAttachment.FindSet() then
            repeat
                NewAttachment := SourceAttachment;
                NewAttachment."No." := ToReportNo;
                NewAttachment."Line No." := ToLineNo;
                NewAttachment.ID := 0;
                NewAttachment.Insert(true);
            until SourceAttachment.Next() = 0;
    end;

    var
        ExpenseReportLine: Record "Expense Report Line";
        HasExpenseReportLine: Boolean;
}
