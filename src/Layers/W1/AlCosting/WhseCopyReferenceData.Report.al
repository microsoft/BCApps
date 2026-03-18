report 103202 "Whse. Copy Reference Data"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'WMS Copy Reference Data';
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
                ILERef."Project Code" := 'WMS';
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

                ILERef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'WAct.Line';

            trigger OnAfterGetRecord()
            begin
                WhseActivLineRef."Project Code" := 'WMS';
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

                WhseActivLineRef.SetRange("Project Code", 'WMS');
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
                WERef."Project Code" := 'WMS';
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

                WERef.SetRange("Project Code", 'WMS');
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
        dataitem("Warehouse Journal Line"; "Warehouse Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Location Code", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Location Code", "Line No.";
            RequestFilterHeading = 'WJnl.Line';

            trigger OnAfterGetRecord()
            begin
                WJLRef."Project Code" := 'WMS';
                WJLRef."Use Case No." := UseCaseNo;
                WJLRef."Test Case No." := TestCaseNo;
                WJLRef."Iteration No." := IterationNo;
                WJLRef.TransferFields("Warehouse Journal Line");
                if not WJLRef.Insert() then
                    WJLRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                WJLRef.SetRange("Project Code", 'WMS');
                WJLRef.SetRange("Use Case No.", UseCaseNo);
                WJLRef.SetRange("Test Case No.", TestCaseNo);
                WJLRef.SetRange("Iteration No.", IterationNo);
                if WJLRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', WJLRef.TableName), false)
                    then
                        CurrReport.Break();
                WJLRef.DeleteAll();
                WJLRef.Reset();
            end;
        }
        dataitem("Item Journal Line"; "Item Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Line No.";
            RequestFilterHeading = 'ItemJnl.Line';

            trigger OnAfterGetRecord()
            begin
                IJLRef."Project Code" := 'WMS';
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

                IJLRef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'BinContent';

            trigger OnAfterGetRecord()
            begin
                BCRef."Project Code" := 'WMS';
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

                BCRef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'WRcpt.Line';

            trigger OnAfterGetRecord()
            begin
                WhseRcptLineRef."Project Code" := 'WMS';
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

                WhseRcptLineRef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'PstdWRcpt.Line';

            trigger OnAfterGetRecord()
            begin
                PostedRcptLineRef."Project Code" := 'WMS';
                PostedRcptLineRef."Use Case No." := UseCaseNo;
                PostedRcptLineRef."Test Case No." := TestCaseNo;
                PostedRcptLineRef."Iteration No." := IterationNo;
                "Posted Whse. Receipt Line".CalcFields("Put-away Qty.", "Put-away Qty. (Base)");
                PostedRcptLineRef.TransferFields("Posted Whse. Receipt Line");
                "Put-away Qty." := "Posted Whse. Receipt Line"."Put-away Qty.";
                "Put-away Qty. (Base)" := "Posted Whse. Receipt Line"."Put-away Qty. (Base)";
                if not PostedRcptLineRef.Insert() then
                    PostedRcptLineRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                PostedRcptLineRef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'WShpt.Line';

            trigger OnAfterGetRecord()
            begin
                WhseShptLineRef."Project Code" := 'WMS';
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

                WhseShptLineRef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'PstdWShpt.Line';

            trigger OnAfterGetRecord()
            begin
                PostedShptLineRef."Project Code" := 'WMS';
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

                PostedShptLineRef.SetRange("Project Code", 'WMS');
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
            RequestFilterHeading = 'WhseWksh.Line';

            trigger OnAfterGetRecord()
            begin
                WhseWkshLineRef."Project Code" := 'WMS';
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

                WhseWkshLineRef.SetRange("Project Code", 'WMS');
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
        dataitem("Prod. Order Component"; "Prod. Order Component")
        {
            DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
            RequestFilterFields = Status, "Prod. Order No.";
            RequestFilterHeading = 'ProdOrderComp';

            trigger OnAfterGetRecord()
            begin
                ProdOrderCompRef."Project Code" := 'WMS';
                ProdOrderCompRef."Use Case No." := UseCaseNo;
                ProdOrderCompRef."Test Case No." := TestCaseNo;
                ProdOrderCompRef."Iteration No." := IterationNo;
                ProdOrderCompRef.TransferFields("Prod. Order Component");
                if not ProdOrderCompRef.Insert() then
                    ProdOrderCompRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                ProdOrderCompRef.SetRange("Project Code", 'WMS');
                ProdOrderCompRef.SetRange("Use Case No.", UseCaseNo);
                ProdOrderCompRef.SetRange("Test Case No.", TestCaseNo);
                ProdOrderCompRef.SetRange("Iteration No.", IterationNo);
                if ProdOrderCompRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', ProdOrderCompRef.TableName), false)
                    then
                        CurrReport.Break();
                ProdOrderCompRef.DeleteAll();
                ProdOrderCompRef.Reset();
            end;
        }
        dataitem("Reservation Entry"; "Reservation Entry")
        {
            DataItemTableView = sorting("Entry No.", Positive);
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'ResEntry';

            trigger OnAfterGetRecord()
            begin
                RERef."Project Code" := 'WMS';
                RERef."Use Case No." := UseCaseNo;
                RERef."Test Case No." := TestCaseNo;
                RERef."Iteration No." := IterationNo;
                RERef.TransferFields("Reservation Entry");
                if not RERef.Insert() then
                    RERef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                RERef.SetRange("Project Code", 'WMS');
                RERef.SetRange("Use Case No.", UseCaseNo);
                RERef.SetRange("Test Case No.", TestCaseNo);
                RERef.SetRange("Iteration No.", IterationNo);
                if RERef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', RERef.TableName), false)
                    then
                        CurrReport.Break();
                RERef.DeleteAll();
                RERef.Reset();
            end;
        }
        dataitem("Tracking Specification"; "Tracking Specification")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'ITSpec';

            trigger OnAfterGetRecord()
            begin
                ITRef."Project Code" := 'WMS';
                ITRef."Use Case No." := UseCaseNo;
                ITRef."Test Case No." := TestCaseNo;
                ITRef."Iteration No." := IterationNo;
                ITRef.TransferFields("Tracking Specification");
                if not ITRef.Insert() then
                    ITRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                ITRef.SetRange("Project Code", 'WMS');
                ITRef.SetRange("Use Case No.", UseCaseNo);
                ITRef.SetRange("Test Case No.", TestCaseNo);
                ITRef.SetRange("Iteration No.", IterationNo);
                if ITRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', ITRef.TableName), false)
                    then
                        CurrReport.Break();
                ITRef.DeleteAll();
                ITRef.Reset();
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
        ILERef: Record "WMS Item Ledger Entry Ref";
        WhseActivLineRef: Record "WMS Whse. Activity Line Ref";
        WERef: Record "WMS Warehouse Entry Ref";
        WJLRef: Record "WMS Warehouse Journal Line Ref";
        IJLRef: Record "WMS Item Journal Line Ref";
        BCRef: Record "WMS Bin Content Ref";
        WhseRcptLineRef: Record "WMS Warehouse Receipt Line Ref";
        PostedRcptLineRef: Record "WMS Posted Whse. Rcpt Line Ref";
        WhseShptLineRef: Record "WMS Whse. Shipment Line Ref";
        PostedShptLineRef: Record "WMS Posted Whse. Shpt Line Ref";
        WhseWkshLineRef: Record "WMS Whse. Worksheet Line Ref";
        ProdOrderCompRef: Record "WMS Prod. Order Component Ref";
        RERef: Record "WMS Reservation Entry Ref";
        ITRef: Record "WMS Tracking Specification Ref";
        UseCaseNo: Integer;
        TestCaseNo: Integer;
        IterationNo: Integer;

    [Scope('OnPrem')]
    procedure CheckIteration()
    begin
        TestIteration.Reset();
        TestIteration.SetRange("Project Code", 'WMS');
        TestIteration.SetRange("Use Case No.", UseCaseNo);
        TestIteration.SetRange("Test Case No.", TestCaseNo);
        TestIteration.SetRange("Iteration No.", IterationNo);
        TestIteration.FindFirst();
    end;
}

