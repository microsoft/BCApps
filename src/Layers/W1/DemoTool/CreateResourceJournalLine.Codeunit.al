codeunit 101207 "Create Resource Journal Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XW0101, 19030102D, XTerry, XCustomer10000, '', 7);
        InsertData(XW0101, 19030102D, XTerry, XCustomer10000, XMILES, 30);
        InsertData(XW0101, 19030103D, XTerry, XCustomer10000, '', 4);
        InsertData(XW0101, 19030103D, XTerry, XCustomer10000, XMILES, 30);
        InsertData(XW0101, 19030103D, XTerry, XAssemblyShop, '', 3);
        InsertData(XW0101, 19030104D, XTerry, XCustomer10000, '', 7);
        InsertData(XW0101, 19030104D, XTerry, XCustomer10000, XMILES, 30);
        InsertData(XW0101, 19030105D, XTerry, XCustomer10000, '', 7);
        InsertData(XW0101, 19030105D, XTerry, XCustomer10000, XMILES, 30);
        InsertData(XW0101, 19030106D, XTerry, XAssemblyShop, '', 8);
        InsertData(XW0201, 19030109D, XTerry, XCustomer20000, '', 7);
        InsertData(XW0201, 19030109D, XTerry, XCustomer20000, XMILES, 24);
        InsertData(XW0201, 19030110D, XTerry, XCustomer20000, '', 4);
        InsertData(XW0201, 19030110D, XTerry, XCustomer20000, XMILES, 24);
        InsertData(XW0201, 19030110D, XTerry, XAssemblyShop, '', 3);
        InsertData(XW0201, 19030111D, XTerry, XCustomer20000, '', 7);
        InsertData(XW0201, 19030111D, XTerry, XCustomer20000, XMILES, 24);
        InsertData(XW0201, 19030112D, XTerry, XCustomer20000, '', 7);
        InsertData(XW0201, 19030112D, XTerry, XCustomer20000, XMILES, 24);
        InsertData(XW0201, 19030113D, XTerry, XAssemblyShop, '', 8);
        InsertData(XW0301, 19030116D, XTerry, XCustomer30000, '', 7);
        InsertData(XW0301, 19030116D, XTerry, XCustomer30000, XMILES, 19);
        InsertData(XW0301, 19030117D, XTerry, XCustomer30000, '', 4);
        InsertData(XW0301, 19030117D, XTerry, XCustomer30000, XMILES, 19);
        InsertData(XW0301, 19030117D, XTerry, XAssemblyShop, '', 3);
        InsertData(XW0301, 19030118D, XTerry, XCustomer30000, '', 7);
        InsertData(XW0301, 19030118D, XTerry, XCustomer30000, XMILES, 19);
        InsertData(XW0301, 19030119D, XTerry, XCustomer30000, '', 7);
        InsertData(XW0301, 19030119D, XTerry, XCustomer30000, XMILES, 19);
        InsertData(XW0301, 19030120D, XTerry, XAssemblyShop, '', 8);
        InsertData(XW0401, 19030123D, XTerry, XCustomer10000, '', 7);
        InsertData(XW0401, 19030123D, XTerry, XCustomer10000, XMILES, 30);
        InsertData(XW0401, 19030124D, XTerry, XCustomer10000, '', 3);
        InsertData(XW0401, 19030124D, XTerry, XCustomer10000, XMILES, 30);
        InsertData(XW0401, 19030124D, XTerry, XAssemblyShop, '', 4);
        InsertData(XW0401, 19030125D, XTerry, XAssemblyShop, '', 8);
        InsertData(XW0401, 19030126D, XTerry, XAssemblyShop, '', 8);
        InsertData(XW0401, 19030127D, XTerry, XAssemblyShop, '', 8);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ResJournalBatch: Record "Res. Journal Batch";
        ResJournalLine: Record "Res. Journal Line";
        BlankResJnlLine: Record "Res. Journal Line";
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        XW0101: Label 'W01-01';
        XW0201: Label 'W02-01';
        XW0301: Label 'W03-01';
        XW0401: Label 'W04-01';
        XTerry: Label 'Terry';
        XCustomer10000: Label 'Customer 10000';
        XCustomer20000: Label 'Customer 20000';
        XAssemblyShop: Label 'Assembly Shop';
        XMILES: Label 'MILES';
        XCustomer30000: Label 'Customer 30000';
        XDEFAULT: Label 'DEFAULT';
        XRESOURCES: Label 'RESOURCES';

    procedure InsertData("Document No.": Code[20]; Date: Date; "Resource No.": Code[20]; Description: Text[50]; "Work Type Code": Code[10]; Quantity: Decimal)
    begin
        Date := CA.AdjustDate(Date);
        InitResJnlLine(ResJournalLine, XRESOURCES, XDEFAULT);
        ResJournalLine.Validate("Document No.", "Document No.");
        ResJournalLine.Validate("Posting Date", Date);
        ResJournalLine.Validate("Resource No.", "Resource No.");
        ResJournalLine.Validate(Description, Description);
        ResJournalLine.Validate("Work Type Code", "Work Type Code");
        ResJournalLine.Validate(Quantity, Quantity);
        ResJournalLine.Insert(true);
    end;

    procedure InitResJnlLine(var ResJournalLine: Record "Res. Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    begin
        ResJournalLine.Init();
        ResJournalLine.Validate("Journal Template Name", "Journal Template Name");
        ResJournalLine.Validate("Journal Batch Name", "Journal Batch Name");
        if ("Journal Template Name" <> ResJournalBatch."Journal Template Name") or
           ("Journal Batch Name" <> ResJournalBatch.Name)
        then begin
            ResJournalBatch.Get("Journal Template Name", "Journal Batch Name");
            if (ResJournalBatch."No. Series" <> '') or
               (ResJournalBatch."Posting No. Series" <> '')
            then begin
                ResJournalBatch."No. Series" := '';
                ResJournalBatch."Posting No. Series" := '';
                ResJournalBatch.Modify();
            end;
        end;
        "Line No." := "Line No." + 10000;
        ResJournalLine.Validate("Line No.", "Line No.");
        ResJournalLine.SetUpNewLine(BlankResJnlLine);
    end;
}

