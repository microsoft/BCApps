#pragma warning disable AA0247
page 26590 "Acc. Schedule Extensions"
{
    Caption = 'Acc. Schedule Extensions';
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SaveValues = true;
    SourceTable = "Acc. Schedule Extension";

    layout
    {
        area(content)
        {
            repeater(Control1470001)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account schedule extension code.';
                }
                field("Source Table"; Rec."Source Table")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source table for the account schedule extension.';
                    Visible = "Source TableVisible";
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the account schedule extension.';
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a location filter to specify that only entries posted to a particular location are to be included in the account schedule.';
                    Visible = "Location FilterVisible";

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocationList: Page "Location List";
                    begin
                        LocationList.LookupMode(true);
                        if not (LocationList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := LocationList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("Value Entry Type Filter"; Rec."Value Entry Type Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value entry type filter associated with the account schedule extension.';
                    Visible = "Value Entry Type FilterVisible";
                }
                field("Inventory Posting Group Filter"; Rec."Inventory Posting Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the inventory posting group that applies to the entry.';
                    Visible = InventoryPostingGroupFilterVis;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        InventoryPostingGroup: Record "Inventory Posting Group";
                        InventoryPostingGroups: Page "Inventory Posting Groups";
                    begin
                        InventoryPostingGroups.LookupMode(true);
                        if not (InventoryPostingGroups.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        InventoryPostingGroups.GetRecord(InventoryPostingGroup);
                        Text := InventoryPostingGroup.Code;

                        exit(true);
                    end;
                }
                field("Item Charge No. Filter"; Rec."Item Charge No. Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item charge number filter associated with the account schedule extension.';
                    Visible = "Item Charge No. FilterVisible";

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemCharge: Record "Item Charge";
                        ItemCharges: Page "Item Charges";
                    begin
                        ItemCharges.LookupMode(true);
                        if not (ItemCharges.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        ItemCharges.GetRecord(ItemCharge);
                        Text := ItemCharge."No.";
                        exit(true);
                    end;
                }
                field("Value Entry Amount Type"; Rec."Value Entry Amount Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value entry amount type associated with the account schedule extension.';
                    Visible = "Value Entry Amount TypeVisible";
                }
                field("VAT Entry Type"; Rec."VAT Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a VAT entry code according to Russian legislation. Some types of documents, such as corrective or revision invoices, must have multiple VAT entry type codes.';
                    Visible = "VAT Entry TypeVisible";
                }
                field("Prepayment Filter"; Rec."Prepayment Filter")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies whether prepayment will be used for the account schedule extension.';
                    Visible = "Prepayment FilterVisible";
                }
                field("VAT Amount Type"; Rec."VAT Amount Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the VAT amount type for the account schedule extension.';
                    Visible = "VAT Amount TypeVisible";
                }
                field("VAT Type"; Rec."VAT Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the VAT type for the account schedule extension.';
                    Visible = "VAT TypeVisible";
                }
                field("VAT Bus. Post. Group Filter"; Rec."VAT Bus. Post. Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the VAT business posting group that applies to the entry.';
                    Visible = VATBusPostGroupFilterVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VATBusinessPostingGroup: Record "VAT Business Posting Group";
                        VATBusinessPostingGroups: Page "VAT Business Posting Groups";
                    begin
                        VATBusinessPostingGroups.LookupMode(true);
                        if not (VATBusinessPostingGroups.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        VATBusinessPostingGroups.GetRecord(VATBusinessPostingGroup);
                        Text := VATBusinessPostingGroup.Code;
                        exit(true);
                    end;
                }
                field("VAT Prod. Post. Group Filter"; Rec."VAT Prod. Post. Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the VAT product posting group that applies to the entry.';
                    Visible = VATProdPostGroupFilterVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VATProductPostingGroup: Record "VAT Product Posting Group";
                        VATProductPostingGroups: Page "VAT Product Posting Groups";
                    begin
                        VATProductPostingGroups.LookupMode(true);
                        if not (VATProductPostingGroups.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        VATProductPostingGroups.GetRecord(VATProductPostingGroup);
                        Text := VATProductPostingGroup.Code;
                        exit(true);
                    end;
                }
                field("Gen. Bus. Post. Group Filter"; Rec."Gen. Bus. Post. Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the general business posting group that applies to the entry.';
                    Visible = GenBusPostGroupFilterVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
                        GenBusinessPostingGroups: Page "Gen. Business Posting Groups";
                    begin
                        GenBusinessPostingGroups.LookupMode(true);
                        if not (GenBusinessPostingGroups.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        GenBusinessPostingGroups.GetRecord(GenBusinessPostingGroup);
                        Text := GenBusinessPostingGroup.Code;
                        exit(true);
                    end;
                }
                field("Gen. Prod. Post. Group Filter"; Rec."Gen. Prod. Post. Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the general product posting group that applies to the entry.';
                    Visible = GenProdPostGroupFilterVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenProductPostingGroup: Record "Gen. Product Posting Group";
                        GenProductPostingGroups: Page "Gen. Product Posting Groups";
                    begin
                        GenProductPostingGroups.LookupMode(true);
                        if not (GenProductPostingGroups.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        GenProductPostingGroups.GetRecord(GenProductPostingGroup);
                        Text := GenProductPostingGroup.Code;
                        exit(true);
                    end;
                }
                field("Object Type Filter"; Rec."Object Type Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object type filter associated with the account schedule extension.';
                    Visible = "Object Type FilterVisible";
                }
                field("Object No. Filter"; Rec."Object No. Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object number filter associated with the account schedule extension.';
                    Visible = "Object No. FilterVisible";

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BankAccount: Record "Bank Account";
                        FixedAsset: Record "Fixed Asset";
                        GLAccList: Page "G/L Account List";
                        CustomerList: Page "Customer List";
                        VendorList: Page "Vendor List";
                        BankAccountList: Page "Bank Account List";
                        FixedAssetList: Page "Fixed Asset List";
                    begin
                        case Rec."Object Type Filter" of
                            Rec."Object Type Filter"::"G/L Account":
                                begin
                                    GLAccList.LookupMode(true);
                                    if not (GLAccList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    Text := GLAccList.GetSelectionFilter();
                                    exit(true);
                                end;
                            Rec."Object Type Filter"::Customer:
                                begin
                                    CustomerList.LookupMode(true);
                                    if not (CustomerList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    Text := CustomerList.GetSelectionFilter();
                                    exit(true);
                                end;
                            Rec."Object Type Filter"::Vendor:
                                begin
                                    VendorList.LookupMode(true);
                                    if not (VendorList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    Text := VendorList.GetSelectionFilter();
                                    exit(true);
                                end;
                            Rec."Object Type Filter"::"Bank Account":
                                begin
                                    BankAccountList.LookupMode(true);
                                    if not (BankAccountList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    BankAccountList.GetRecord(BankAccount);
                                    Text := BankAccount."No.";
                                    exit(true);
                                end;
                            Rec."Object Type Filter"::"Fixed Asset":
                                begin
                                    FixedAssetList.LookupMode(true);
                                    if not (FixedAssetList.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    FixedAssetList.GetRecord(FixedAsset);
                                    Text := FixedAsset."No.";
                                    exit(true);
                                end;
                        end;
                    end;
                }
                field("VAT Allocation Type Filter"; Rec."VAT Allocation Type Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the VAT allocation type filter associated with the account schedule extension.';
                    Visible = VATAllocationTypeFilterVisible;
                }
                field("Liability Type"; Rec."Liability Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the liability type associated with the account schedule extension.';
                    Visible = "Liability TypeVisible";
                }
                field("Due Date Filter"; Rec."Due Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the due date for the account schedule extension.';
                    Visible = "Due Date FilterVisible";
                }
                field("Amount Sign"; Rec."Amount Sign")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount sign for the account schedule extension.';
                    Visible = "Amount SignVisible";
                }
                field("Document Type Filter"; Rec."Document Type Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type for the account schedule extension.';
                    Visible = "Document Type FilterVisible";
                }
                field("Posting Date Filter"; Rec."Posting Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date for the account schedule extension.';
                    Visible = "Posting Date FilterVisible";
                }
                field("Reverse Sign"; Rec."Reverse Sign")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if you want positive amounts to be shown as negative amounts or negative amounts to be shown as positive.';
                    Visible = "Reverse SignVisible";
                }
                field("Posting Group Filter"; Rec."Posting Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting group for the account schedule extension.';
                    Visible = "Posting Group FilterVisible";

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomerPostingGroup: Record "Customer Posting Group";
                        VendorPostingGroup: Record "Vendor Posting Group";
                        CustomerPostingGroups: Page "Customer Posting Groups";
                        VendorPostingGroups: Page "Vendor Posting Groups";
                    begin
                        case Rec."Source Table" of
                            Rec."Source Table"::"Customer Entry":
                                begin
                                    CustomerPostingGroups.LookupMode(true);
                                    if not (CustomerPostingGroups.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    CustomerPostingGroups.GetRecord(CustomerPostingGroup);
                                    Text := CustomerPostingGroup.Code;
                                    exit(true);
                                end;
                            Rec."Source Table"::"Vendor Entry":
                                begin
                                    VendorPostingGroups.LookupMode(true);
                                    if not (VendorPostingGroups.RunModal() = ACTION::LookupOK) then
                                        exit(false);
                                    VendorPostingGroups.GetRecord(VendorPostingGroup);
                                    Text := VendorPostingGroup.Code;
                                    exit(true);
                                end;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        "Value Entry Amount TypeVisible" := true;
        "Item Charge No. FilterVisible" := true;
        InventoryPostingGroupFilterVis := true;
        "Value Entry Type FilterVisible" := true;
        "Document Type FilterVisible" := true;
        "Liability TypeVisible" := true;
        "Due Date FilterVisible" := true;
        "Posting Date FilterVisible" := true;
        "Posting Group FilterVisible" := true;
        "Location FilterVisible" := true;
        VATAllocationTypeFilterVisible := true;
        "Object No. FilterVisible" := true;
        "Object Type FilterVisible" := true;
        GenProdPostGroupFilterVisible := true;
        GenBusPostGroupFilterVisible := true;
        VATProdPostGroupFilterVisible := true;
        VATBusPostGroupFilterVisible := true;
        "VAT TypeVisible" := true;
        "VAT Amount TypeVisible" := true;
        "Reverse SignVisible" := true;
        "Prepayment FilterVisible" := true;
        "VAT Entry TypeVisible" := true;
        "Amount SignVisible" := true;
        "Source TableVisible" := true;
    end;

    trigger OnOpenPage()
    begin
        if SourceTable <> SourceTable::" " then
            UpdateControls();
    end;

    var
        SourceTable: Option " ","VAT Entry","Value Entry","Customer Entry","Vendor Entry";
        "Source TableVisible": Boolean;
        "Amount SignVisible": Boolean;
        "VAT Entry TypeVisible": Boolean;
        "Prepayment FilterVisible": Boolean;
        "Reverse SignVisible": Boolean;
        "VAT Amount TypeVisible": Boolean;
        "VAT TypeVisible": Boolean;
        VATBusPostGroupFilterVisible: Boolean;
        VATProdPostGroupFilterVisible: Boolean;
        GenBusPostGroupFilterVisible: Boolean;
        GenProdPostGroupFilterVisible: Boolean;
        "Object Type FilterVisible": Boolean;
        "Object No. FilterVisible": Boolean;
        VATAllocationTypeFilterVisible: Boolean;
        "Location FilterVisible": Boolean;
        "Posting Group FilterVisible": Boolean;
        "Posting Date FilterVisible": Boolean;
        "Due Date FilterVisible": Boolean;
        "Liability TypeVisible": Boolean;
        "Document Type FilterVisible": Boolean;
        "Value Entry Type FilterVisible": Boolean;
        InventoryPostingGroupFilterVis: Boolean;
        "Item Charge No. FilterVisible": Boolean;
        "Value Entry Amount TypeVisible": Boolean;

    [Scope('OnPrem')]
    procedure SetSourceTable(NewSourceTable: Integer)
    begin
        SourceTable := NewSourceTable;
    end;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        "Source TableVisible" := false;
        "Amount SignVisible" := false;
        "VAT Entry TypeVisible" := false;
        "Prepayment FilterVisible" := false;
        "Reverse SignVisible" := false;
        "VAT Amount TypeVisible" := false;
        "VAT TypeVisible" := false;
        VATBusPostGroupFilterVisible := false;
        VATProdPostGroupFilterVisible := false;
        GenBusPostGroupFilterVisible := false;
        GenProdPostGroupFilterVisible := false;
        "Object Type FilterVisible" := false;
        "Object No. FilterVisible" := false;
        VATAllocationTypeFilterVisible := false;
        "Location FilterVisible" := false;
        "Posting Group FilterVisible" := false;
        "Posting Date FilterVisible" := false;
        "Due Date FilterVisible" := false;
        "Liability TypeVisible" := false;
        "Document Type FilterVisible" := false;
        "Value Entry Type FilterVisible" := false;
        InventoryPostingGroupFilterVis := false;
        "Item Charge No. FilterVisible" := false;
        "Value Entry Amount TypeVisible" := false;

        case SourceTable of
            SourceTable::"VAT Entry":
                begin
                    "VAT Entry TypeVisible" := true;
                    "Reverse SignVisible" := true;
                    "VAT Amount TypeVisible" := true;
                    "VAT TypeVisible" := true;
                    VATBusPostGroupFilterVisible := true;
                    VATProdPostGroupFilterVisible := true;
                    GenBusPostGroupFilterVisible := true;
                    GenProdPostGroupFilterVisible := true;
                    "Object Type FilterVisible" := true;
                    "Object No. FilterVisible" := true;
                    VATAllocationTypeFilterVisible := true;
                    "Prepayment FilterVisible" := true;
                end;
            SourceTable::"Value Entry":
                begin
                    "Location FilterVisible" := true;
                    "Value Entry Type FilterVisible" := true;
                    InventoryPostingGroupFilterVis := true;
                    "Item Charge No. FilterVisible" := true;
                    "Value Entry Amount TypeVisible" := true;
                    "Reverse SignVisible" := true;
                    "Amount SignVisible" := true;
                end;
            SourceTable::"Customer Entry",
            SourceTable::"Vendor Entry":
                begin
                    "Posting Group FilterVisible" := true;
                    "Posting Date FilterVisible" := true;
                    "Liability TypeVisible" := true;
                    "Due Date FilterVisible" := true;
                    "Document Type FilterVisible" := true;
                    "Prepayment FilterVisible" := true;
                    "Amount SignVisible" := true;
                    "Reverse SignVisible" := true;
                end;
        end;
    end;
}

