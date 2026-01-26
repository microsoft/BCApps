codeunit 163527 "Create Compensation Line CZC"
{

    trigger OnRun()
    begin
        EntryAmount := 0;
        InsertData('ZAP0001', Enum::"Compensation Source Type CZC"::Customer, '10000', 3, '104001');
        InsertData('ZAP0001', Enum::"Compensation Source Type CZC"::Customer, '10000', 2, '103017');
        InsertData('ZAP0002', Enum::"Compensation Source Type CZC"::Vendor, '30000', 2, '108031');
        InsertData('ZAP0002', Enum::"Compensation Source Type CZC"::Vendor, '30000', 3, '109001');
    end;

    var
        CompensationLineCZC: Record "Compensation Line CZC";
        LineNo: Integer;
        PreviousDocumentNo: Code[20];
        EntryAmount: Decimal;

    procedure InsertData(CompensationNo: Code[20]; SourceType: Enum "Compensation Source Type CZC"; SourceCompanyNo: Code[20]; SourceDocumentType: Option; SourceDocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CompensationLineCZC.Init();
        CompensationLineCZC."Compensation No." := CompensationNo;

        if PreviousDocumentNo = CompensationNo then begin
            LineNo := LineNo + 10000;
            CompensationLineCZC.Validate("Line No.", LineNo);
        end else begin
            LineNo := 10000;
            PreviousDocumentNo := CompensationNo;
            CompensationLineCZC.Validate("Line No.", LineNo);
        end;

        CompensationLineCZC."Source Type" := SourceType;

        case CompensationLineCZC."Source Type" of
            CompensationLineCZC."Source Type"::Customer:
                begin
                    CustLedgerEntry.SetRange("Customer No.", SourceCompanyNo);
                    CustLedgerEntry.SetRange("Document Type", SourceDocumentType);
                    CustLedgerEntry.SetRange("Document No.", SourceDocumentNo);
                    CustLedgerEntry.SetRange(Open, true);
                    if CustLedgerEntry.FindFirst() then begin
                        CompensationLineCZC.Validate("Source Entry No.", CustLedgerEntry."Entry No.");

                        if EntryAmount = 0 then
                            EntryAmount := CompensationLineCZC."Amount (LCY)"
                        else begin
                            CompensationLineCZC.Validate("Amount (LCY)", -EntryAmount);
                            EntryAmount := 0;
                        end;

                        CompensationLineCZC.Insert();
                    end;
                end;
            CompensationLineCZC."Source Type"::Vendor:
                begin
                    VendorLedgerEntry.SetRange("Vendor No.", SourceCompanyNo);
                    VendorLedgerEntry.SetRange("Document Type", SourceDocumentType);
                    VendorLedgerEntry.SetRange("Document No.", SourceDocumentNo);
                    VendorLedgerEntry.SetRange(Open, true);
                    if VendorLedgerEntry.FindFirst() then begin
                        CompensationLineCZC.Validate("Source Entry No.", VendorLedgerEntry."Entry No.");

                        if EntryAmount = 0 then
                            EntryAmount := CompensationLineCZC."Amount (LCY)"
                        else begin
                            CompensationLineCZC.Validate("Amount (LCY)", -EntryAmount);
                            EntryAmount := 0;
                        end;

                        CompensationLineCZC.Insert();
                    end;
                end;
        end;
    end;
}

