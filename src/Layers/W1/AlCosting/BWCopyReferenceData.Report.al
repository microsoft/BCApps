report 103231 "BW Copy Reference Data"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'BW Copy Reference Data';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Ledger Entry"; "Item Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'ILE';

            trigger OnAfterGetRecord()
            begin
                ILERef."Use Case No." := UseCaseNo;
                ILERef."Test Case No." := TestCaseNo;
                ILERef."Iteration No." := IterationNo;
                ILERef.TransferFields("Item Ledger Entry");
                if not ILERef.Insert() then
                    ILERef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                ILERef.SetRange("Use Case No.", UseCaseNo);
                ILERef.SetRange("Test Case No.", TestCaseNo);
                ILERef.SetRange("Iteration No.", IterationNo);
                if ILERef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', ILERef.TableName), false)
                    then
                        CurrReport.Break();
                ILERef.DeleteAll();
                ILERef.Reset();
            end;
        }
        dataitem("Warehouse Activity Line"; "Warehouse Activity Line")
        {
            DataItemTableView = sorting("Activity Type", "No.", "Line No.");
            RequestFilterFields = "Activity Type", "No.", "Line No.";
            RequestFilterHeading = 'WAct.Ln';

            trigger OnAfterGetRecord()
            begin
                WhseActivLineRef."Use Case No." := UseCaseNo;
                WhseActivLineRef."Test Case No." := TestCaseNo;
                WhseActivLineRef."Iteration No." := IterationNo;
                WhseActivLineRef.TransferFields("Warehouse Activity Line");
                if not WhseActivLineRef.Insert() then
                    WhseActivLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WhseActivLineRef.SetRange("Use Case No.", UseCaseNo);
                WhseActivLineRef.SetRange("Test Case No.", TestCaseNo);
                WhseActivLineRef.SetRange("Iteration No.", IterationNo);
                if WhseActivLineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WhseActivLineRef.TableName), false)
                    then
                        CurrReport.Break();
                WhseActivLineRef.DeleteAll();
                WhseActivLineRef.Reset();
            end;
        }
        dataitem("Warehouse Entry"; "Warehouse Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'WEntry';

            trigger OnAfterGetRecord()
            begin
                WERef."Use Case No." := UseCaseNo;
                WERef."Test Case No." := TestCaseNo;
                WERef."Iteration No." := IterationNo;
                WERef.TransferFields("Warehouse Entry");
                if not WERef.Insert() then
                    WERef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WERef.SetRange("Use Case No.", UseCaseNo);
                WERef.SetRange("Test Case No.", TestCaseNo);
                WERef.SetRange("Iteration No.", IterationNo);
                if WERef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WERef.TableName), false)
                    then
                        CurrReport.Break();
                WERef.DeleteAll();
                WERef.Reset();
            end;
        }
        dataitem("Item Journal Line"; "Item Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Line No.";
            RequestFilterHeading = 'ItemJnl.Ln';

            trigger OnAfterGetRecord()
            begin
                IJLRef."Use Case No." := UseCaseNo;
                IJLRef."Test Case No." := TestCaseNo;
                IJLRef."Iteration No." := IterationNo;
                IJLRef.TransferFields("Item Journal Line");
                if not IJLRef.Insert() then
                    IJLRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                IJLRef.SetRange("Use Case No.", UseCaseNo);
                IJLRef.SetRange("Test Case No.", TestCaseNo);
                IJLRef.SetRange("Iteration No.", IterationNo);
                if IJLRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', IJLRef.TableName), false)
                    then
                        CurrReport.Break();
                IJLRef.DeleteAll();
                IJLRef.Reset();
            end;
        }
        dataitem("Bin Content"; "Bin Content")
        {
            DataItemTableView = sorting("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
            RequestFilterFields = "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code";
            RequestFilterHeading = 'BinCont';

            trigger OnAfterGetRecord()
            begin
                BCRef."Use Case No." := UseCaseNo;
                BCRef."Test Case No." := TestCaseNo;
                BCRef."Iteration No." := IterationNo;
                CalcFields(
                  Quantity, "Pick Qty.", "Neg. Adjmt. Qty.", "Put-away Qty.", "Pos. Adjmt. Qty.");
                BCRef.TransferFields("Bin Content");
                BCRef.Quantity := Quantity;
                BCRef."Pick Qty." := "Pick Qty.";
                BCRef."Neg. Adjmt. Qty." := "Neg. Adjmt. Qty.";
                BCRef."Put-away Qty." := "Put-away Qty.";
                BCRef."Pos. Adjmt. Qty." := "Pos. Adjmt. Qty.";
                if not BCRef.Insert() then
                    BCRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                BCRef.SetRange("Use Case No.", UseCaseNo);
                BCRef.SetRange("Test Case No.", TestCaseNo);
                BCRef.SetRange("Iteration No.", IterationNo);
                if BCRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', BCRef.TableName), false)
                    then
                        CurrReport.Break();
                BCRef.DeleteAll();
                BCRef.Reset();
            end;
        }
        dataitem("Warehouse Receipt Line"; "Warehouse Receipt Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            RequestFilterFields = "No.", "Line No.";
            RequestFilterHeading = 'WRcpt.Ln';

            trigger OnAfterGetRecord()
            begin
                WhseRcptLineRef."Use Case No." := UseCaseNo;
                WhseRcptLineRef."Test Case No." := TestCaseNo;
                WhseRcptLineRef."Iteration No." := IterationNo;
                WhseRcptLineRef.TransferFields("Warehouse Receipt Line");
                if not WhseRcptLineRef.Insert() then
                    WhseRcptLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WhseRcptLineRef.SetRange("Use Case No.", UseCaseNo);
                WhseRcptLineRef.SetRange("Test Case No.", TestCaseNo);
                WhseRcptLineRef.SetRange("Iteration No.", IterationNo);
                if WhseRcptLineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WhseRcptLineRef.TableName), false)
                    then
                        CurrReport.Break();
                WhseRcptLineRef.DeleteAll();
                WhseRcptLineRef.Reset();
            end;
        }
        dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            RequestFilterFields = "No.", "Line No.";
            RequestFilterHeading = 'PstdWRcpt.Ln';

            trigger OnAfterGetRecord()
            begin
                PostedRcptLineRef."Use Case No." := UseCaseNo;
                PostedRcptLineRef."Test Case No." := TestCaseNo;
                PostedRcptLineRef."Iteration No." := IterationNo;
                "Posted Whse. Receipt Line".CalcFields("Put-away Qty.", "Put-away Qty. (Base)");
                PostedRcptLineRef.TransferFields("Posted Whse. Receipt Line");
                PostedRcptLineRef."Put-away Qty." := "Posted Whse. Receipt Line"."Put-away Qty.";
                PostedRcptLineRef."Put-away Qty. (Base)" := "Posted Whse. Receipt Line"."Put-away Qty. (Base)";
                if not PostedRcptLineRef.Insert() then
                    PostedRcptLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                PostedRcptLineRef.SetRange("Use Case No.", UseCaseNo);
                PostedRcptLineRef.SetRange("Test Case No.", TestCaseNo);
                PostedRcptLineRef.SetRange("Iteration No.", IterationNo);
                if PostedRcptLineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', PostedRcptLineRef.TableName), false)
                    then
                        CurrReport.Break();
                PostedRcptLineRef.DeleteAll();
                PostedRcptLineRef.Reset();
            end;
        }
        dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            RequestFilterFields = "No.", "Line No.";
            RequestFilterHeading = 'WShpt.Ln';

            trigger OnAfterGetRecord()
            begin
                WhseShptLineRef."Use Case No." := UseCaseNo;
                WhseShptLineRef."Test Case No." := TestCaseNo;
                WhseShptLineRef."Iteration No." := IterationNo;
                WhseShptLineRef.TransferFields("Warehouse Shipment Line");
                if not WhseShptLineRef.Insert() then
                    WhseShptLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WhseShptLineRef.SetRange("Use Case No.", UseCaseNo);
                WhseShptLineRef.SetRange("Test Case No.", TestCaseNo);
                WhseShptLineRef.SetRange("Iteration No.", IterationNo);
                if WhseShptLineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WhseShptLineRef.TableName), false)
                    then
                        CurrReport.Break();
                WhseShptLineRef.DeleteAll();
                WhseShptLineRef.Reset();
            end;
        }
        dataitem("Posted Whse. Shipment Line"; "Posted Whse. Shipment Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            RequestFilterFields = "No.", "Line No.";
            RequestFilterHeading = 'PstdWShpt.Ln';

            trigger OnAfterGetRecord()
            begin
                PostedShptLineRef."Use Case No." := UseCaseNo;
                PostedShptLineRef."Test Case No." := TestCaseNo;
                PostedShptLineRef."Iteration No." := IterationNo;
                PostedShptLineRef.TransferFields("Posted Whse. Shipment Line");
                if not PostedShptLineRef.Insert() then
                    PostedShptLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                PostedShptLineRef.SetRange("Use Case No.", UseCaseNo);
                PostedShptLineRef.SetRange("Test Case No.", TestCaseNo);
                PostedShptLineRef.SetRange("Iteration No.", IterationNo);
                if PostedShptLineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', PostedShptLineRef.TableName), false)
                    then
                        CurrReport.Break();
                PostedShptLineRef.DeleteAll();
                PostedShptLineRef.Reset();
            end;
        }
        dataitem("Whse. Worksheet Line"; "Whse. Worksheet Line")
        {
            DataItemTableView = sorting("Worksheet Template Name", Name, "Location Code", "Line No.");
            RequestFilterFields = Name, "Location Code", "Line No.";
            RequestFilterHeading = 'WhseWksh.Ln';

            trigger OnAfterGetRecord()
            begin
                WhseWkshLineRef."Use Case No." := UseCaseNo;
                WhseWkshLineRef."Test Case No." := TestCaseNo;
                WhseWkshLineRef."Iteration No." := IterationNo;
                WhseWkshLineRef.TransferFields("Whse. Worksheet Line");
                if not WhseWkshLineRef.Insert() then
                    WhseWkshLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WhseWkshLineRef.SetRange("Use Case No.", UseCaseNo);
                WhseWkshLineRef.SetRange("Test Case No.", TestCaseNo);
                WhseWkshLineRef.SetRange("Iteration No.", IterationNo);
                if WhseWkshLineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WhseWkshLineRef.TableName), false)
                    then
                        CurrReport.Break();
                WhseWkshLineRef.DeleteAll();
                WhseWkshLineRef.Reset();
            end;
        }
        dataitem("Warehouse Request"; "Warehouse Request")
        {
            DataItemTableView = sorting(Type, "Location Code", "Source Type", "Source Subtype", "Source No.");
            RequestFilterFields = Type, "Location Code", "Source Type", "Source Subtype", "Source No.";
            RequestFilterHeading = 'WhseReq';

            trigger OnAfterGetRecord()
            begin
                WhseReqRef."Use Case No." := UseCaseNo;
                WhseReqRef."Test Case No." := TestCaseNo;
                WhseReqRef."Iteration No." := IterationNo;
                WhseReqRef.TransferFields("Warehouse Request");
                if not WhseReqRef.Insert() then
                    WhseReqRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WhseReqRef.SetRange("Use Case No.", UseCaseNo);
                WhseReqRef.SetRange("Test Case No.", TestCaseNo);
                WhseReqRef.SetRange("Iteration No.", IterationNo);
                if WhseReqRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WhseReqRef.TableName), false)
                    then
                        CurrReport.Break();
                WhseReqRef.DeleteAll();
                WhseReqRef.Reset();
            end;
        }
        dataitem("Item Register"; "Item Register")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'ItemReg';

            trigger OnAfterGetRecord()
            begin
                ItemRegRef."Use Case No." := UseCaseNo;
                ItemRegRef."Test Case No." := TestCaseNo;
                ItemRegRef."Iteration No." := IterationNo;
                ItemRegRef.TransferFields("Item Register");
                if not ItemRegRef.Insert() then
                    ItemRegRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                ItemRegRef.SetRange("Use Case No.", UseCaseNo);
                ItemRegRef.SetRange("Test Case No.", TestCaseNo);
                ItemRegRef.SetRange("Iteration No.", IterationNo);
                if ItemRegRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', ItemRegRef.TableName), false)
                    then
                        CurrReport.Break();
                ItemRegRef.DeleteAll();
                ItemRegRef.Reset();
            end;
        }
        dataitem("Posted Invt. Put-away Line"; "Posted Invt. Put-away Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            RequestFilterFields = "No.", "Line No.";
            RequestFilterHeading = 'PstIPULn';

            trigger OnAfterGetRecord()
            begin
                PstIPULineRef."Use Case No." := UseCaseNo;
                PstIPULineRef."Test Case No." := TestCaseNo;
                PstIPULineRef."Iteration No." := IterationNo;
                PstIPULineRef.TransferFields("Posted Invt. Put-away Line");
                if not PstIPULineRef.Insert() then
                    PstIPULineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                PstIPULineRef.SetRange("Use Case No.", UseCaseNo);
                PstIPULineRef.SetRange("Test Case No.", TestCaseNo);
                PstIPULineRef.SetRange("Iteration No.", IterationNo);
                if PstIPULineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', PstIPULineRef.TableName), false)
                    then
                        CurrReport.Break();
                PstIPULineRef.DeleteAll();
                PstIPULineRef.Reset();
            end;
        }
        dataitem("Posted Invt. Pick Line"; "Posted Invt. Pick Line")
        {
            DataItemTableView = sorting("No.", "Line No.");
            RequestFilterFields = "No.", "Line No.";
            RequestFilterHeading = 'PstIPILn';

            trigger OnAfterGetRecord()
            begin
                PstIPILineRef."Use Case No." := UseCaseNo;
                PstIPILineRef."Test Case No." := TestCaseNo;
                PstIPILineRef."Iteration No." := IterationNo;
                PstIPILineRef.TransferFields("Posted Invt. Pick Line");
                if not PstIPILineRef.Insert() then
                    PstIPILineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                PstIPILineRef.SetRange("Use Case No.", UseCaseNo);
                PstIPILineRef.SetRange("Test Case No.", TestCaseNo);
                PstIPILineRef.SetRange("Iteration No.", IterationNo);
                if PstIPILineRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', PstIPILineRef.TableName), false)
                    then
                        CurrReport.Break();
                PstIPILineRef.DeleteAll();
                PstIPILineRef.Reset();
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

    trigger OnPreReport()
    begin
        CheckIteration();
    end;

    var
        TestIteration: Record "Whse. Test Iteration";
        ILERef: Record "BW Item Ledger Entry Ref";
        WhseActivLineRef: Record "BW Warehouse Activity Line Ref";
        WERef: Record "BW Warehouse Entry Ref";
        IJLRef: Record "BW Item Journal Line Ref.";
        BCRef: Record "BW Bin Content Ref";
        WhseRcptLineRef: Record "BW Warehouse Receipt Line Ref";
        PostedRcptLineRef: Record "BW Posted Whse. Rcpt Line Ref";
        WhseShptLineRef: Record "BW Warehouse Shipment Line Ref";
        PostedShptLineRef: Record "BW Posted Whse. Shpmt Line Ref";
        WhseWkshLineRef: Record "BW Whse. Worksheet Line Ref";
        WhseReqRef: Record "BW Warehouse Request Ref";
        ItemRegRef: Record "BW Item Register Ref";
        PstIPULineRef: Record "BW P. Invt. Put-away Line Ref";
        PstIPILineRef: Record "BW P. Invt. Pick Line Ref";
        UseCaseNo: Integer;
        TestCaseNo: Integer;
        IterationNo: Integer;

    [Scope('OnPrem')]
    procedure CheckIteration()
    begin
        TestIteration.Reset();
        TestIteration.SetRange("Project Code", 'BW');
        TestIteration.SetRange("Use Case No.", UseCaseNo);
        TestIteration.SetRange("Test Case No.", TestCaseNo);
        TestIteration.SetRange("Iteration No.", IterationNo);
        TestIteration.FindFirst();
    end;
}

