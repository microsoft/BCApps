#pragma warning disable AA0247
report 14915 "Supplement to INV-17"
{
    Caption = 'Supplement to INV-17';
    ProcessingOnly = true;

    dataset
    {
        dataitem(InventActHeader; "Invent. Act Header")
        {
            PrintOnlyIfDetail = true;
            dataitem(InventActLine; "Invent. Act Line")
            {
                DataItemLink = "Act No." = field("No.");
                DataItemTableView = sorting("Act No.", "Contractor Type", "Contractor No.", "Posting Group", Category);
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("Contractor No."), "Customer Posting Group" = field("Posting Group");
                    DataItemTableView = sorting("Customer No.", "Posting Date", "Currency Code");

                    trigger OnAfterGetRecord()
                    begin
                        if InventActLine."Contractor Type" = InventActLine."Contractor Type"::Vendor then
                            CurrReport.Skip();

                        SetRange("Date Filter", 0D, InventActHeader."Inventory Date");
                        CalcFields("Remaining Amt. (LCY)");

                        if "Remaining Amt. (LCY)" = 0 then
                            CurrReport.Skip();

                        DebtsAmount := 0;
                        LiabilitiesAmount := 0;

                        if InventActLine.Category = InventActLine.Category::Debts then begin
                            if "Remaining Amt. (LCY)" < 0 then
                                CurrReport.Skip();
                            DebtsAmount := "Remaining Amt. (LCY)"
                        end else begin
                            if "Remaining Amt. (LCY)" > 0 then
                                CurrReport.Skip();
                            LiabilitiesAmount := -"Remaining Amt. (LCY)";
                        end;

                        Customer.Get("Customer No.");
                        if "Agreement No." <> '' then
                            CustAgrmt.Get("Customer No.", "Agreement No.");

                        Counter += 1;

                        INV17Helper.FillAppndxLine(
                          Format(Counter),
                          Customer.Name + Customer."Name 2" + ', ' + Customer.Address +
                          Customer."Address 2" + ', ' + Customer."Phone No.",
                          Description + ' ' + CustAgrmt.Description, Format("Posting Date"),
                          Format(DebtsAmount), Format(LiabilitiesAmount),
                          Format("Document Type"), Format("Document No."), Format("Posting Date"));
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Customer Posting Group", InventActLine."Posting Group");
                        SetRange("Posting Date", 0D, InventActHeader."Inventory Date");
                    end;
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("Contractor No.");
                    DataItemTableView = sorting("Vendor No.", "Posting Date", "Currency Code");

                    trigger OnAfterGetRecord()
                    begin
                        if InventActLine."Contractor Type" = InventActLine."Contractor Type"::Customer then
                            CurrReport.Skip();

                        SetRange("Date Filter", 0D, InventActHeader."Inventory Date");
                        CalcFields("Remaining Amt. (LCY)");

                        if "Remaining Amt. (LCY)" = 0 then
                            CurrReport.Skip();

                        DebtsAmount := 0;
                        LiabilitiesAmount := 0;

                        if InventActLine.Category = InventActLine.Category::Debts then begin
                            if "Remaining Amt. (LCY)" < 0 then
                                CurrReport.Skip();
                            DebtsAmount := "Remaining Amt. (LCY)"
                        end else begin
                            if "Remaining Amt. (LCY)" > 0 then
                                CurrReport.Skip();
                            LiabilitiesAmount := -"Remaining Amt. (LCY)";
                        end;

                        Vendor.Get("Vendor No.");
                        if "Agreement No." <> '' then
                            VendAgrmt.Get("Vendor No.", "Agreement No.");

                        Counter += 1;

                        INV17Helper.FillAppndxLine(
                          Format(Counter),
                          Vendor.Name + Vendor."Name 2" + ', ' + Vendor.Address + Vendor."Address 2" +
                          ', ' + Vendor."Phone No.",
                          Description + ' ' + VendAgrmt.Description, Format("Posting Date"),
                          Format(DebtsAmount), Format(LiabilitiesAmount),
                          Format("Document Type"), Format("Document No."), Format("Posting Date"));
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Vendor Posting Group", InventActLine."Posting Group");
                        SetRange("Posting Date", 0D, InventActHeader."Inventory Date");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                INV17Helper.CheckSignature(Accountant, "No.", Accountant."Employee Type"::Accountant);
                INV17Helper.FillAppndxHeader("No.", "Act Date", "Inventory Date");
                INV17Helper.FillAppndxPageHeader();
            end;

            trigger OnPostDataItem()
            begin
                INV17Helper.FillAppndxFooter(Accountant."Employee Name");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName = '' then
            INV17Helper.ExportData()
        else
            INV17Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        GLSetup.Get();
        INV17Helper.InitReportTemplate(REPORT::"Supplement to INV-17");
    end;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Accountant: Record "Document Signature";
        CustAgrmt: Record "Customer Agreement";
        VendAgrmt: Record "Vendor Agreement";
        INV17Helper: Codeunit "INV-17 Report Helper";
        FileName: Text;
        Counter: Integer;
        DebtsAmount: Decimal;
        LiabilitiesAmount: Decimal;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

