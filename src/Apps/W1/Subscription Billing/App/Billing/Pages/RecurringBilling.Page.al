namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Dimension;
using System.Utilities;

page 8067 "Recurring Billing"
{
    ApplicationArea = All;
    Caption = 'Recurring Billing';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Billing Line";
    SourceTableTemporary = true;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'Recurring Billing, Create Invoice, Billing Proposal, Contract Billing, Subscription Billing, Invoice Generation';
    AboutTitle = 'About Recurring Billing';
    AboutText = 'Use this page to prepare the billing of subscriptions and contracts. It creates a billing proposal before actual invoicing.';

    layout
    {
        area(Content)
        {
            group(BillingTemplateFilter)
            {
                Caption = 'Filter';
                field(BillingTemplateField; BillingTemplate.Code)
                {
                    Caption = 'Billing Template';
                    ToolTip = 'Specifies the name of the template that is used to calculate billable Subscription Lines.';
                    AboutTitle = 'Defined views';
                    AboutText = 'Personalized views help to create billing proposals.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupBillingTemplate();
                    end;

                    trigger OnValidate()
                    begin
                        FindBillingTemplate();
                    end;
                }
                field(BillingDateField; BillingDate)
                {
                    Caption = 'Billing Date';
                    ToolTip = 'Specifies the date up to which the billable Subscription Lines will be taken into account.';
                }
                field(BillingToDateField; BillingToDate)
                {
                    Caption = 'Billing to Date';
                    ToolTip = 'Specifies the optional date up to which the billable Subscription Lines should be charged.';
                }
            }
            repeater(BillingLines)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indent;
                TreeInitialState = CollapseAll;

                field("Partner No."; Rec."Partner No.")
                {
                    ToolTip = 'Specifies the number of the partner who will receive the contract components and be billed by default.';
                    StyleExpr = LineStyleExpr;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ContractsGeneralMgt.OpenPartnerCard(Rec.Partner, Rec."Partner No.");
                        RefreshCurrentRowGroup();
                    end;
                }
                field("Partner Name"; PartnerNameTxt)
                {
                    Caption = 'Partner Name';
                    ToolTip = 'Specifies the name of the partner who will receive the contract components and be billed by default.';
                    StyleExpr = LineStyleExpr;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        ContractsGeneralMgt.OpenPartnerCard(Rec.Partner, Rec."Partner No.");
                        RefreshCurrentRowGroup();
                    end;
                }
                field("Contract No."; Rec."Subscription Contract No.")
                {
                    ToolTip = 'Specifies the number of the Subscription Contract.';
                    StyleExpr = LineStyleExpr;

                    trigger OnDrillDown()
                    begin
                        ContractsGeneralMgt.OpenContractCard(Rec.Partner, Rec."Subscription Contract No.");
                        RefreshCurrentRowGroup();
                    end;
                }
                field(ContractDescriptionField; ContractDescriptionTxt)
                {
                    Caption = 'Subscription Contract Description';
                    ToolTip = 'Specifies the description of the Subscription Contract.';
                    Editable = false;
                    StyleExpr = LineStyleExpr;

                    trigger OnDrillDown()
                    begin
                        ContractsGeneralMgt.OpenContractCard(Rec.Partner, Rec."Subscription Contract No.");
                        RefreshCurrentRowGroup();
                    end;
                }
                field("Billing from"; Rec."Billing from")
                {
                    ToolTip = 'Specifies the date from which the Subscription Line is billed.';
                    StyleExpr = LineStyleExpr;
                }
                field("Billing to"; Rec."Billing to")
                {
                    ToolTip = 'Specifies the date to which the Subscription Line is billed.';
                    StyleExpr = LineStyleExpr;
                }
                field("Billing Reference Date Changed"; Rec."Billing Reference Date Changed")
                {
                    StyleExpr = LineStyleExpr;
                    Visible = false;
                }
                field("Service Amount"; Rec.Amount)
                {
                    ToolTip = 'Specifies the amount for the Subscription Line including discount.';
                    StyleExpr = LineStyleExpr;
                    AboutTitle = 'What''s the amount to be invoiced?';
                    AboutText = 'The overview shows what is supposed to be invoiced per subscription and contract.';
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ToolTip = 'Specifies the unit cost for the billing period.';
                    StyleExpr = LineStyleExpr;
                    BlankZero = true;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ToolTip = 'Specifies the Unit Price for the subscription line billing period without discount.';
                    StyleExpr = LineStyleExpr;
                    BlankZero = true;
                }
                field("Service Object Quantity"; Rec."Service Object Quantity")
                {
                    ToolTip = 'Specifies the quantity from the Subscription.';
                    StyleExpr = LineStyleExpr;
                    BlankZero = true;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ToolTip = 'Specifies the Discount % for the subscription line billing period.';
                    StyleExpr = LineStyleExpr;
                }
                field("Service Commitment Description"; Rec."Subscription Line Description")
                {
                    ToolTip = 'Specifies the description of the Subscription Line.';
                    StyleExpr = LineStyleExpr;
                }
                field("Billing Rhythm"; Rec."Billing Rhythm")
                {
                    ToolTip = 'Specifies the Dateformula for rhythm in which the Subscription Line is invoiced. Using a Dateformula rhythm can be, for example, a monthly, a quarterly or a yearly invoicing.';
                    StyleExpr = LineStyleExpr;
                }
                field("Update Required"; Rec."Update Required")
                {
                    ToolTip = 'Specifies whether the associated Subscription Line has been changed. The "Create Billing Proposal" function must be called up again before the billing document is created.';
                    StyleExpr = LineStyleExpr;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the document type of the document created for posting.';
                    StyleExpr = LineStyleExpr;
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the document number of the document created for posting.';
                    StyleExpr = LineStyleExpr;

                    trigger OnDrillDown()
                    begin
                        RefreshAfterDocumentDrillDown();
                    end;
                }
                field("Service Start Date"; Rec."Subscription Line Start Date")
                {
                    ToolTip = 'Specifies the date from which the Subscription Line is valid and will be invoiced.';
                    StyleExpr = LineStyleExpr;
                }
                field("Service End Date"; Rec."Subscription Line End Date")
                {
                    ToolTip = 'Specifies the date up to which the Subscription Line is valid.';
                    StyleExpr = LineStyleExpr;
                }
                field("Service Object No."; Rec."Subscription Header No.")
                {
                    ToolTip = 'Specifies the number of the Subscription.';
                    StyleExpr = LineStyleExpr;

                    trigger OnDrillDown()
                    begin
                        ServiceObject.OpenServiceObjectCard(Rec."Subscription Header No.");
                        RefreshCurrentRowGroup();
                    end;
                }
                field("Service Object Description"; Rec."Subscription Description")
                {
                    ToolTip = 'Specifies a description of the Subscription.';
                    StyleExpr = LineStyleExpr;
                }
                field("Billing Template Code"; Rec."Billing Template Code")
                {
                    ToolTip = 'Specifies the template code.';
                    StyleExpr = LineStyleExpr;
                    Visible = false;
                }
                field(Discount; Rec.Discount)
                {
                    ToolTip = 'Specifies whether the Subscription Line is used as a basis for periodic invoicing or discounts.';
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the user who created the line.';
                    StyleExpr = LineStyleExpr;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateBillingProposalAction)
            {
                Caption = 'Create Billing Proposal';
                Image = Process;
                ToolTip = 'Suggests the Subscription Lines to be billed based on the selected billing template. The billing proposal can be supplemented by changing the billing template and calling it up again.';
                AboutTitle = 'Suggest contract lines to be billed based on the selected criteria.';
                AboutText = 'The contract lines to be invoiced are proposed before the invoice is issued.';

                trigger OnAction()
                begin
                    BillingProposal.CreateBillingProposal(BillingTemplate.Code, BillingDate, BillingToDate);
                    InitTempTable();
                end;
            }
            action(CreateDocuments)
            {
                Caption = 'Create Documents';
                Image = CreateDocuments;
                Scope = Page;
                ToolTip = 'The action creates contract invoices or credit memos for the billing lines displayed on this page.';
                AboutTitle = 'How to create invoices?';
                AboutText = 'Invoices can be created in batches and posted immediately if required.';

                trigger OnAction()
                var
                    ErrorMessageMgt: Codeunit "Error Message Management";
                    ErrorMessageHandler: Codeunit "Error Message Handler";
                    ErrorContextElement: Codeunit "Error Context Element";
                    CreateBillingDocuments: Codeunit "Create Billing Documents";
                    DocumentDate: Date;
                    PostingDate: Date;
                    IsSuccess: Boolean;
                begin
                    ErrorMessageMgt.Activate(ErrorMessageHandler);
                    ErrorMessageMgt.PushContext(ErrorContextElement, 0, 0, '');
                    Commit(); //commit to database before processing
                    if BillingTemplate.Get(BillingTemplate.Code) then begin
                        BillingTemplate.CalculateDocumentDates(PostingDate, DocumentDate, false);
                        if BillingTemplate.Partner = BillingTemplate.Partner::Customer then
                            CreateBillingDocuments.SetCustomerRecurringBillingGrouping(BillingTemplate."Customer Document per");
                        CreateBillingDocuments.SetDocumentDataFromRequestPage(DocumentDate, PostingDate, false, false);
                    end;
                    IsSuccess := CreateBillingDocuments.Run(Rec);
                    if not IsSuccess then
                        ErrorMessageHandler.ShowErrors();
                    InitTempTable();
                end;
            }
            action(UsageData)
            {
                ApplicationArea = All;
                Caption = 'Usage Data';
                Image = DataEntry;
                Scope = Repeater;
                ToolTip = 'Shows the related usage data.';
                Enabled = UsageDataEnabled;
                trigger OnAction()
                var
                    UsageDataBilling: Record "Usage Data Billing";
                begin
                    UsageDataBilling.ShowForRecurringBilling(Rec."Subscription Header No.", Rec."Subscription Line Entry No.", Rec."Document Type", Rec."Document No.");
                end;
            }
            action(ClearBillingProposalAction)
            {
                Caption = 'Clear Billing Proposal';
                Image = CancelAllLines;
                ToolTip = 'Deletes the current billing proposal in whole or in part.';

                trigger OnAction()
                begin
                    BillingProposal.DeleteBillingProposal(BillingTemplate.Code);
                    InitTempTable();
                end;
            }
            action(DeleteDocuments)
            {
                Caption = 'Delete Documents';
                Image = Delete;
                ToolTip = 'Deletes all contract invoices und credit memos.';

                trigger OnAction()
                begin
                    BillingProposal.DeleteBillingDocuments(BillingTemplate.Code);
                    InitTempTable();
                end;
            }
            action(ChangeBillingToAction)
            {
                Caption = 'Change Billing To Date';
                Image = ChangeDate;
                Scope = Repeater;
                ToolTip = 'This can be used to change the end of billing.';

                trigger OnAction()
                var
                    BillingLine: Record "Billing Line";
                    ChangeDate: Page "Change Date";
                    NewBillingToDate: Date;
                    AffectedGroupKeys: List of [Code[20]];
                begin
                    if BillingDate <> 0D then
                        ChangeDate.SetDate(BillingDate);
                    if ChangeDate.RunModal() = Action::OK then
                        NewBillingToDate := ChangeDate.GetDate()
                    else
                        exit;
                    CurrPage.SetSelectionFilter(BillingLine);
                    CollectSelectionGroupKeys(BillingLine, AffectedGroupKeys);
                    BillingProposal.UpdateBillingToDate(BillingLine, NewBillingToDate);
                    RefreshGroups(AffectedGroupKeys);
                end;
            }
            action(DeleteBillingLineAction)
            {
                Caption = 'Delete Billing Line';
                Image = Delete;
                Scope = Page;
                ToolTip = 'This can be used to delete selected billing lines.';

                trigger OnAction()
                var
                    BillingLine: Record "Billing Line";
                    AffectedGroupKeys: List of [Code[20]];
                begin
                    CurrPage.SetSelectionFilter(BillingLine);
                    CollectSelectionGroupKeys(BillingLine, AffectedGroupKeys);
                    BillingProposal.DeleteBillingLines(BillingLine);
                    RefreshGroups(AffectedGroupKeys);
                end;
            }
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                Scope = Page;
                ToolTip = 'Refreshes the current view.';
                ShortcutKey = 'F5';

                trigger OnAction()
                begin
                    InitTempTable();
                end;
            }
        }

        area(Navigation)
        {
            action(OpenPartnerAction)
            {
                Caption = 'Customer/Vendor';
                Image = Customer;
                Scope = Repeater;
                ToolTip = 'Opens the Customer/Vendor card.';

                trigger OnAction()
                begin
                    ContractsGeneralMgt.OpenPartnerCard(Rec.Partner, Rec."Partner No.");
                    RefreshCurrentRowGroup();
                end;
            }
            action(OpenContractAction)
            {
                Caption = 'Contract';
                Image = Document;
                Scope = Repeater;
                ToolTip = 'Opens the Contract card.';

                trigger OnAction()
                begin
                    ContractsGeneralMgt.OpenContractCard(Rec.Partner, Rec."Subscription Contract No.");
                    RefreshCurrentRowGroup();
                end;
            }
            action(OpenServiceObjectAction)
            {
                Caption = 'Subscription';
                Image = ServiceAgreement;
                Scope = Repeater;
                ToolTip = 'Opens the Subscription card.';

                trigger OnAction()
                begin
                    ServiceObject.OpenServiceObjectCard(Rec."Subscription Header No.");
                    RefreshCurrentRowGroup();
                end;
            }
            action(Dimensions)
            {
                AccessByPermission = tabledata Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Contract Line Dimensions';
                Image = Dimensions;
                Scope = Repeater;
                ShortcutKey = 'Shift+Ctrl+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    UpdateServiceCommitmentDimension();
                end;
            }
        }

        area(Promoted)
        {
            actionref(CreateBillingProposalAction_Promoted; CreateBillingProposalAction) { }
            actionref(CreateDocuments_Promoted; CreateDocuments) { }
            actionref("UsageData_Promoted"; UsageData) { }
            actionref(ClearBillingProposalAction_Promoted; ClearBillingProposalAction) { }
            actionref(DeleteDocuments_Promoted; DeleteDocuments) { }
            actionref(ChangeBillingToAction_Promoted; ChangeBillingToAction) { }
            actionref(DeleteBillingLineAction_Promoted; DeleteBillingLineAction) { }
            actionref(Refresh_Promoted; Refresh) { }

            group(Navigate_Promoted)
            {
                Caption = 'Navigate';

                actionref(OpenPartnerAction_Promoted; OpenPartnerAction) { }
                actionref(OpenContractAction_Promoted; OpenContractAction) { }
                actionref(OpenServiceObjectAction_Promoted; OpenServiceObjectAction) { }
                actionref(Dimensions_Promoted; Dimensions) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FindBillingTemplate();
    end;

    trigger OnAfterGetRecord()
    begin
        // Resolve the contract description and partner name from per-page caches: OnAfterGetRecord fires on every
        // row of every render cycle, and the same contract/partner repeats across many rows, so an uncached lookup
        // per row turns into thousands of redundant Get calls. The caches are reset whenever the lines are rebuilt.
        ContractDescriptionTxt := GetCachedContractDescription(Rec.Partner, Rec."Subscription Contract No.");
        PartnerNameTxt := GetCachedPartnerName(Rec.Partner, Rec."Partner No.");
        SetLineStyleExpr();
    end;

    trigger OnAfterGetCurrRecord()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataEnabled := UsageDataBilling.ExistForRecurringBilling(Rec."Subscription Header No.", Rec."Subscription Line Entry No.", Rec."Document Type", Rec."Document No.");
    end;

    var
        BillingTemplate: Record "Billing Template";
        ServiceObject: Record "Subscription Header";
        ContractsGeneralMgt: Codeunit "Sub. Contracts General Mgt.";
        BillingProposal: Codeunit "Billing Proposal";
        ContractDescriptionTxt: Text;
        PartnerNameTxt: Text;
        GroupBy: Enum "Contract Billing Grouping";
        UsageDataEnabled: Boolean;
        ContractDescriptionCache: Dictionary of [Text, Text];
        PartnerNameCache: Dictionary of [Text, Text];

    protected var
        BillingDate: Date;
        BillingToDate: Date;
        LineStyleExpr: Text;

    local procedure LookupBillingTemplate()
    var
        BillingTemplate2: Record "Billing Template";
    begin
        BillingTemplate2 := BillingTemplate;
        if Page.RunModal(0, BillingTemplate2) = Action::LookupOK then begin
            BillingTemplate := BillingTemplate2;
            ApplyBillingTemplateFilter(BillingTemplate);
            InitTempTable();
        end;
    end;

    local procedure FindBillingTemplate()
    var
        SearchText: Text;
    begin
        SearchText := BillingTemplate.Code;
        if SearchText <> '' then begin
            BillingTemplate.SetRange(Code, SearchText);
            if not BillingTemplate.FindFirst() then begin
                SearchText := DelChr(SearchText, '<>', ' ');
                SearchText := DelChr(SearchText, '=', '()<>\');
                SearchText := '*' + SearchText + '*';
                BillingTemplate.SetFilter(Code, SearchText);
                if not BillingTemplate.FindFirst() then
                    Clear(BillingTemplate);
            end;
        end;
        if BillingTemplate.Get(BillingTemplate.Code) then
            ApplyBillingTemplateFilter(BillingTemplate);
        InitTempTable();
    end;

    local procedure ApplyBillingTemplateFilter(var BillingTemplate2: Record "Billing Template")
    begin
        BillingTemplate2.CalculateBillingDates(BillingDate, BillingToDate, false);
        if BillingTemplate2."My Suggestions Only" then
            Rec.SetRange("User ID", UserId())
        else
            Rec.SetRange("User ID");

        Rec.SetRange(Partner, BillingTemplate2.Partner);
        GroupBy := BillingTemplate2."Group by";
        OnAfterApplyBillingTemplateFilter(BillingTemplate2);
    end;

    local procedure SetLineStyleExpr()
    begin
        case true of
            Rec."Update Required":
                LineStyleExpr := 'Unfavorable';
            Rec.Indent = 0:
                LineStyleExpr := 'Strong';
            else
                LineStyleExpr := '';
        end;
    end;

    procedure InitTempTable()
    begin
        // The lines are about to be rebuilt, so drop the row-render caches; contract descriptions or partner names
        // may have changed since they were last read.
        Clear(ContractDescriptionCache);
        Clear(PartnerNameCache);
        BillingProposal.InitTempTable(Rec, GroupBy);
        if Rec.FindFirst() then; //to enable CollapseAll
        CurrPage.Update(false);
    end;

    // Rebuilds the temp table group that contains the current row. Called after any drilldown or navigate action
    // that opens a card which may have been edited (partner name, contract discount, subscription quantity, etc.).
    local procedure RefreshCurrentRowGroup()
    var
        GroupKeys: List of [Code[20]];
    begin
        GroupKeys.Add(GetGroupKey(Rec."Partner No.", Rec."Subscription Contract No."));
        RefreshGroups(GroupKeys);
    end;

    // Special refresh for the Document No. drilldown: a document may be deleted inside the card, which clears
    // Document No. on all billing lines it covered — potentially across multiple groups for collective documents.
    // All affected groups are captured before the card opens, so the rebuild is correct regardless of what changes.
    local procedure RefreshAfterDocumentDrillDown()
    var
        TempDocumentBillingLine: Record "Billing Line" temporary;
        AffectedGroupKeys: List of [Code[20]];
        GroupKey: Code[20];
    begin
        if Rec."Document No." = '' then
            exit;
        TempDocumentBillingLine.Copy(Rec, true); // shared-table copy — no data copy, cursor untouched
        TempDocumentBillingLine.Reset();
        TempDocumentBillingLine.SetRange("Document Type", Rec."Document Type");
        TempDocumentBillingLine.SetRange("Document No.", Rec."Document No.");
        if TempDocumentBillingLine.FindSet() then
            repeat
                GroupKey := GetGroupKey(TempDocumentBillingLine."Partner No.", TempDocumentBillingLine."Subscription Contract No.");
                if not AffectedGroupKeys.Contains(GroupKey) then
                    AffectedGroupKeys.Add(GroupKey);
            until TempDocumentBillingLine.Next() = 0;

        Rec.OpenDocumentCard();

        // RefreshGroups preserves Rec's position; if the document was deleted and the billing line no longer
        // exists it falls back to the first record automatically.
        RefreshGroups(AffectedGroupKeys);
    end;

    // Collects the group key for each line in the selection before a mutating action (Delete Billing Line,
    // Change Billing To Date) runs, so only those groups need rebuilding afterwards.
    local procedure CollectSelectionGroupKeys(var BillingLine: Record "Billing Line"; var GroupKeys: List of [Code[20]])
    var
        GroupKey: Code[20];
    begin
        if BillingLine.FindSet() then
            repeat
                GroupKey := GetGroupKey(BillingLine."Partner No.", BillingLine."Subscription Contract No.");
                if not GroupKeys.Contains(GroupKey) then
                    GroupKeys.Add(GroupKey);
            until BillingLine.Next() = 0;
    end;

    // Returns the grouping key for a billing line: the contract no. for Contract grouping, the partner no. for
    // Contract Partner grouping. Centralizes the GroupBy decision so callers do not repeat it.
    local procedure GetGroupKey(PartnerNo: Code[20]; ContractNo: Code[20]): Code[20]
    begin
        if GroupBy = GroupBy::"Contract Partner" then
            exit(PartnerNo);
        exit(ContractNo);
    end;

    // Common entry point for all targeted refreshes: clears the per-page render caches, rebuilds the specified
    // groups in the temp table, and refreshes the page. The user's current row position is preserved; if the row
    // no longer exists after the rebuild (e.g. it was deleted), the page falls back to the first record.
    local procedure RefreshGroups(GroupKeys: List of [Code[20]])
    var
        CurrentEntryNo: Integer;
    begin
        CurrentEntryNo := Rec."Entry No.";
        Clear(ContractDescriptionCache);
        Clear(PartnerNameCache);
        BillingProposal.RefreshGroupsInTempTable(Rec, GroupBy, GroupKeys);
        if not Rec.Get(CurrentEntryNo) then
            if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure GetCachedContractDescription(Partner: Enum "Service Partner"; ContractNo: Code[20]): Text
    var
        CacheKey: Text;
        CachedValue: Text;
    begin
        if ContractNo = '' then
            exit('');
        CacheKey := Format(Partner) + '|' + ContractNo;
        if ContractDescriptionCache.Get(CacheKey, CachedValue) then
            exit(CachedValue);
        CachedValue := ContractsGeneralMgt.GetContractDescription(Partner, ContractNo);
        ContractDescriptionCache.Add(CacheKey, CachedValue);
        exit(CachedValue);
    end;

    local procedure GetCachedPartnerName(Partner: Enum "Service Partner"; PartnerNo: Code[20]): Text
    var
        CacheKey: Text;
        CachedValue: Text;
    begin
        if PartnerNo = '' then
            exit('');
        CacheKey := Format(Partner) + '|' + PartnerNo;
        if PartnerNameCache.Get(CacheKey, CachedValue) then
            exit(CachedValue);
        CachedValue := ContractsGeneralMgt.GetPartnerName(Partner, PartnerNo);
        PartnerNameCache.Add(CacheKey, CachedValue);
        exit(CachedValue);
    end;

    local procedure UpdateServiceCommitmentDimension()
    var
        ServiceCommitment: Record "Subscription Line";
    begin
        ServiceCommitment.Get(Rec."Subscription Line Entry No.");
        ServiceCommitment.EditDimensionSet();
        CurrPage.Update();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterApplyBillingTemplateFilter(var SelectedBillingTemplate: Record "Billing Template")
    begin
    end;
}
