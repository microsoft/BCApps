namespace Microsoft.CRM.Outlook;
using Microsoft.CRM.Contact;

page 7100 "Contact Sync"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Synchronize contacts';

    layout
    {
        area(content)
        {
            group(Step1)
            {
                Caption = 'Welcome';
                Visible = Step = Step::Welcome;

                group(WelcomeGroup)
                {
                    Caption = '';
                    field(WelcomeText; WelcomeTextTxt)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                        Style = Standard;
                    }
                }
            }
#if not CLEAN29
            group(AuthGroup)
            {
                Caption = '';
                InstructionalText = 'Click on Next to authenticate with Microsoft 365 and retrieve contact folders.';
                ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                Visible = false;
            }
#endif
            group(Step2)
            {
                Caption = 'Contact Filter';
                Visible = Step = Step::ContactFilter;
                group(ContactFilterGroup)
                {
                    Caption = '';
                    InstructionalText = 'You can synchronize all person contacts from the current company in Business Central, or filter the list to focus on specific person contacts.';

                    field(ContactFilter; ContactFilterText)
                    {
                        ApplicationArea = All;
                        Caption = 'Choose contacts';
                        Editable = false;
                        ToolTip = 'Specify filters on different fields, such as salesperson code, to reduce the list of contacts that will be synchronized. Leave this blank to synchronize all contacts.';

                        trigger OnAssistEdit()
                        var
                            ContactRec: Record "Contact";
                            FilterPageBuilder: FilterPageBuilder;
                            ContactTxt: Text;
                        begin
                            ContactTxt := ContactRec.TableCaption();
                            FilterPageBuilder.AddTable('Contact', Database::Contact);
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec."Territory Code");
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec."Company No.");
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec."Salesperson Code");
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec.City);
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec.County);
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec."Post Code");
                            FilterPageBuilder.ADdField(ContactTxt, ContactRec."Country/Region Code");

                            if ContactFilterText <> '' then
                                FilterPageBuilder.SetView('Contact', ContactFilterText);

                            if FilterPageBuilder.RunModal() then begin
                                ContactFilterText := FilterPageBuilder.GetView('Contact', false);

                                ContactRec.SetView(ContactFilterText);
                                Message(TotalRecordsMessageLbl, ContactRec.Count);
                            end;
                        end;
                    }
                    field(FolderListField; SelectedFolderName)
                    {
                        ApplicationArea = All;
                        Caption = 'Contacts folder';
                        ToolTip = 'Specifies the name of the folder in Outlook and Teams which will be used for synchronization. This helps segregate your business contacts from any other contacts.';
                        Lookup = true;
                        ShowMandatory = true;
                        QuickEntry = false;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            TempFolder: Record "Contact Sync Folder" temporary;
                        begin
                            TempFolder.Copy(TempSyncFolder, true);
                            TempFolder.Reset();

                            if Page.RunModal(Page::"Folder Lookup", TempFolder) = Action::LookupOK then begin
                                SelectedFolderId := TempFolder."Folder ID";
                                SelectedFolderName := TempFolder."Display Name";
                                Text := SelectedFolderName;
                                PreviousFolderName := SelectedFolderName;      // Store last selection
                                exit(true);
                            end;

                            exit(false);
                        end;

                        trigger OnValidate()
                        begin
                            // Trigger validation even if user clears the field
                            if SelectedFolderName <> PreviousFolderName then begin
                                if SelectedFolderName = '' then
                                    Error(ErrorFolderEmptyMsg);
                                TempSyncFolder.Reset();
                                TempSyncFolder.SetRange("Display Name", SelectedFolderName);
                                if not TempSyncFolder.FindFirst() then
                                    Error(ErrorInvalidFolderMsg);
                                PreviousFolderName := SelectedFolderName;  // Update tracker
                            end;
                        end;
                    }
                    field(fullSyncField; FullSyncOption)
                    {
                        ApplicationArea = All;
                        Caption = 'Force full sync';
                        ToolTip = 'When this is enabled, Business Central will synchronize contacts no matter when they were last modified. This may take longer, but can overcome some synchronization issues.';
                    }
                    field(PreviewText; PreviewTextLbl)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        MultiLine = false;
                        ShowCaption = false;
                        Style = Subordinate;
                    }
                    field(LastsyncDateFolderTime; GetLastSyncDateTime())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        MultiLine = false;
                        ShowCaption = false;
                        Style = Subordinate;
                    }
                }
            }
            group(Step3)
            {
                Caption = 'Synchronize Contacts';
                Visible = Step = Step::SyncOptions;

                group(SyncOptionsGroup)
                {
                    Caption = '';
                    InstructionalText = 'We found some contacts that match your criteria. Choose Synchronize to begin. This can take a few minutes if you have many contacts.';
                    field(SyncDirectionField; SyncDirection)
                    {
                        ApplicationArea = All;
                        Caption = 'What to update';
                        ToolTip = 'Specifies the direction of synchronization. If you only update Outlook and Teams, no changes will be made to the contact list in Business Central. If you update both, the contacts from the specified folder in Outlook and Teams will also be copied back to Business Central and other users may be able to see them.';
                        ShowMandatory = true;
                        QuickEntry = false;
                    }
                    field(SyncToM365Button; GetContactsToAddOutlookLabel())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        ShowCaption = false;
                        Style = StandardAccent;
                        StyleExpr = true;

                        trigger OnDrillDown()
                        var
                            TempFilteredQueue: Record "Contact Sync Queue" temporary;
                            SyncQueueDialog: Page "Contact Sync Queue Dialog";
                            Caption: Text;
                        begin
                            TempFilteredQueue.Copy(TempSyncContacts, true);
                            TempFilteredQueue.Reset();
                            TempFilteredQueue.SetRange("Sync Direction", 0);
                            SyncQueueDialog.SetData(TempFilteredQueue);
                            Caption := CaptionToSyncO365Txt;
                            SyncQueueDialog.setCaption(Caption);
                            SyncQueueDialog.RunModal();
                        end;
                    }
                    field(SyncToBCButton; GetContactsToAddBCLabel())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        ShowCaption = false;
                        Style = StandardAccent;
                        StyleExpr = true;

                        trigger OnDrillDown()
                        var
                            TempFilteredQueue: Record "Contact Sync Queue" temporary;
                            SyncQueueDialog: Page "Contact Sync Queue Dialog";
                            caption: Text;
                        begin
                            TempFilteredQueue.Copy(TempSyncContacts, true);
                            TempFilteredQueue.Reset();
                            TempFilteredQueue.SetRange("Sync Direction", 1);
                            SyncQueueDialog.SetData(TempFilteredQueue);
                            caption := CaptionToSyncBCTxt;
                            SyncQueueDialog.setCaption(caption);
                            SyncQueueDialog.RunModal();
                        end;
                    }
                }
            }
#if not CLEAN29
            group(Step6)
            {
                Caption = 'Synchronize Contacts';
                Visible = false;
                ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
            }
            group(Step7)
            {
                Caption = 'Completed';
                Visible = false;
                ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
            }
#endif
            group(Step4)
            {
                Caption = 'Completed';
                Visible = Step = Step::Finish;
#if not CLEAN29
                group(ReadyGroup)
                {
                    Caption = '';
                    InstructionalText = '';
                    Visible = false;
                    ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';

                    field(ReadyText; ReadyTextTxt)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                        Visible = false;
                        ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '29.0';
                    }
                }
#endif
                group(FinishGroupFinal)
                {
                    Caption = '';
                    InstructionalText = 'Synchronization has completed successfully.';
                    Visible = not NoContactsToSync;
                    field(SyncTimeField; GetSyncTimeLabel())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        ToolTip = 'Specifies the time taken to complete the synchronization.';
                    }
                    field(ContactsSentToM365Field; GetContactsSentToM365Label())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        ToolTip = 'Specifies the number of contacts sent to Outlook and Teams.';
                    }
                    field(ContactsSentToBCField; GetContactsSentToBCLabel())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        ToolTip = 'Specifies the number of contacts sent to Business Central.';
                    }
                    field(ContactsFailedField; GetContactsFailedLabel())
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the number of contacts that failed to synchronize.';
                        Style = Unfavorable;
                        StyleExpr = ContactsFailedCount > 0;
                        Visible = ContactsFailedCount > 0;

                        trigger OnDrillDown()
                        var
                            TempFilteredQueue: Record "Contact Sync Queue" temporary;
                            SyncQueueDialog: Page "Contact Sync Queue Dialog";
                            caption: Text;
                        begin
                            TempFilteredQueue.Copy(TempSyncContacts, true);
                            TempFilteredQueue.Reset();
                            TempFilteredQueue.SetRange("Sync Status", TempFilteredQueue."Sync Status"::Error);
                            SyncQueueDialog.SetData(TempFilteredQueue);
                            caption := FailedSyncLbl;
                            SyncQueueDialog.setCaption(caption);
                            SyncQueueDialog.RunModal();
                        end;
                    }
                }

                group(FinishGroupFinalNosync)
                {
                    Caption = '';
                    InstructionalText = 'No contacts available to synchronize. You can close this wizard now.';
                    Visible = NoContactsToSync;
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = BackEnabled;

                trigger OnAction()
                begin
                    GoToStep(Step - 1);
                end;
            }

            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = NextEnabled;

                trigger OnAction()
                var
                    GraphMgt: Codeunit "O365 Bidirectional Sync";
                    O365GraphAuth: Codeunit "O365 Graph Authentication";
                begin
                    if Step = Step::Welcome then begin
                        O365GraphAuth.GetAccessToken(AccessToken);
                        if AccessToken.IsEmpty() then begin
                            Session.LogMessage('0000QU2', ErrTelTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                            Error(ErrorObtainingTokenMsg);
                        end;
                        // Populate folder options
                        PopulateFolderOptions(TempSyncFolder);
                        GraphMgt.GetContactFolders(AccessToken, TempSyncFolder);
                        if (TempSyncFolder.Count() = 0) then begin
                            Session.LogMessage('0000QU3', NoFolderMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                            GraphMgt.CreateFolderinO365(AccessToken, TempSyncFolder, FolderName);
                        end;
                        if (SelectedFolderName = '') and (TempSyncFolder.FindFirst()) then begin
                            SelectedFolderId := TempSyncFolder."Folder ID";
                            SelectedFolderName := TempSyncFolder."Display Name";
                            PreviousFolderName := SelectedFolderName;
                        end;
                        // Update delta link for each folder
                        TempSyncFolder.Reset();
                        TempSyncFolder.SetLoadFields("Folder ID", "Display Name");
                        if TempSyncFolder.FindSet() then
                            repeat
                                UpdateFolderId(TempSyncFolder."Folder ID", '', TempSyncFolder."Display Name");
                            until TempSyncFolder.Next() = 0;
                    end;
                    if Step = Step::ContactFilter then
                        if SelectedFolderId = '' then
                            Error(ErrorSelectFolderMsg);
                    if Step = Step::ContactFilter then begin
                        // Fetch contacts when moving from Ready step
                        Deltalink := '';
                        TempSyncContacts.DeleteAll();
                        GraphMgt.GetContacts(AccessToken, TempSyncContacts, ContactFilterText, SelectedFolderId, FullSyncOption, Deltalink);
                    end;

                    GoToStep(Step + 1);
                end;
            }

            action(ActionFetch)
            {
                ApplicationArea = All;
                Caption = 'Synchronize';
                Image = Approve;
                InFooterBar = true;
                Enabled = FinishEnabled;

                trigger OnAction()
                var
                    SyncProcessor: Codeunit "Contact Sync Processor";
                    BCcount: Integer;
                    M365count: Integer;
                    StartTime: DateTime;
                begin
                    case Step of
                        Step::SyncOptions:
                            begin
                                BCcount := GetSyncToBCCount();
                                M365count := GetSyncToM365Count();
                                Session.LogMessage('0000QU4', StrSubstNo(SyncCountsTelLbl, BCcount, M365count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);

                                if (BCcount + M365count) = 0 then begin
                                    Session.LogMessage('0000QU5', NoContactsToSyncTelLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                                    Error(NoSyncMsg);
                                end;

                                if (SyncDirection = SyncDirection::"Full Sync") and not (BCcount = 0) then
                                    if Confirm(DisclaimerLbl) then
                                        Session.LogMessage('0000RRF', StrSubstNo(SyncAcknowledgementTelTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl)
                                    else
                                        exit;
                                if (SyncDirection = SyncDirection::"Sync from BC to M365") and (M365count = 0) then begin
                                    Session.LogMessage('0000QU6', NoContactsBCToM365TelLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                                    Error(NoSyncMsg);
                                end
                                else begin
                                    Session.LogMessage('0000QU7', StrSubstNo(StartingSyncTelLbl, SyncDirection), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                                    StartTime := CurrentDateTime();
                                    SyncProcessor.ProcessBidirectionalSync(TempSyncContacts, accessToken, SelectedFolderId, SyncDirection);
                                    SyncTimeText := Format(CurrentDateTime() - StartTime);
                                    Session.LogMessage('0000QU8', StrSubstNo(SyncCompletedTelLbl, SyncTimeText), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                                end;
                                UpdateFolderId(SelectedFolderId, Deltalink, SelectedFolderName);
                                UpdateSyncCounts();
                                Session.LogMessage('0000QU9', StrSubstNo(SyncResultsTelLbl, ContactsSentToM365Count, ContactsSentToBCCount, ContactsFailedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, CategoryLbl);
                                GoToStep(Step::Finish);
                            end;
                    end;
                end;
            }
            action(ActionClose)
            {
                ApplicationArea = All;
                Caption = 'Close';
                Image = Close;
                InFooterBar = true;
                Visible = Step = Step::Finish;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        NewLineChar := 10;
        Step := Step::Welcome;
        WelcomeTextTxt := WelcomeTextLbl;
        FolderName := 'Business Central';
        SyncDirection := SyncDirection::"Sync from BC to M365";
        ReadyTextTxt := '';
        UpdateControls();
    end;

    local procedure UpdateSyncCounts()
    var
        TempQueue: Record "Contact Sync Queue" temporary;
    begin
        ContactsSentToM365Count := 0;
        ContactsSentToBCCount := 0;
        ContactsFailedCount := 0;

        TempQueue.Copy(TempSyncContacts, true);
        TempQueue.Reset();

        TempQueue.SetRange("Sync Status", TempQueue."Sync Status"::Processed);
        TempQueue.SetRange("Sync Direction", 0);
        ContactsSentToM365Count := TempQueue.Count();

        TempQueue.Reset();
        TempQueue.SetRange("Sync Status", TempQueue."Sync Status"::Processed);
        TempQueue.SetRange("Sync Direction", 1);
        ContactsSentToBCCount := TempQueue.Count();

        TempQueue.Reset();
        TempQueue.SetRange("Sync Status", TempQueue."Sync Status"::Error);
        ContactsFailedCount := TempQueue.Count();
    end;

    local procedure UpdateFolderId(FolderId: Text; NewDeltaLink: Text; FolderName: Text)
    var
        ContactSyncUserRec: Record "Contact Sync User";
    begin
        ContactSyncUserRec.Reset();
        ContactSyncUserRec.SetRange("User ID", CopyStr(UserId(), 1, 50));
        ContactSyncUserRec.SetRange("Folder ID", CopyStr(FolderId, 1, 250));
        ContactSyncUserRec.SetLoadFields("Delta Url", "Folder Name", "Folder ID", "Last Sync Date Time");
        if not ContactSyncUserRec.FindFirst() then begin
            ContactSyncUserRec.Init();
            ContactSyncUserRec."User ID" := CopyStr(UserId(), 1, 50);
            ContactSyncUserRec."Folder ID" := CopyStr(FolderId, 1, 250);
            ContactSyncUserRec."Folder Name" := CopyStr(FolderName, 1, 250);
            ContactSyncUserRec.Insert(true);
        end
        else
            if not (NewDeltaLink = '') then begin
                ContactSyncUserRec.SetDeltaUrl(CopyStr(NewDeltaLink, 1, 2048));
                ContactSyncUserRec."Last Sync Date Time" := CurrentDateTime();
                ContactSyncUserRec.Modify(false);
            end;
    end;

    local procedure GoToStep(NewStep: Option)
    begin
        Step := NewStep;
        UpdateControls();
    end;

    local procedure GetLastSyncDateTime(): Text
    var
        ContactSyncUserRec: Record "Contact Sync User";
    begin
        ContactSyncUserRec.Reset();
        ContactSyncUserRec.SetRange("User ID", CopyStr(UserId(), 1, 50));
        ContactSyncUserRec.SetRange("Folder ID", CopyStr(SelectedFolderId, 1, 250));
        ContactSyncUserRec.SetFilter("Last Sync Date Time", '<>%1', 0DT);
        ContactSyncUserRec.SetLoadFields("Last Sync Date Time", "Folder Name");
        ContactSyncUserRec.SetCurrentKey("Last Sync Date Time");
        ContactSyncUserRec.Ascending(true);
        if ContactSyncUserRec.FindLast() then
            exit(Format(ContactSyncUserRec."Folder Name" + ' ' + SyncedAtTxt + ' ' + Format(ContactSyncUserRec."Last Sync Date Time")))
        else
            exit(NoSyncFoundTxt);
    end;

    local procedure UpdateControls()
    begin
        BackEnabled := (Step > Step::Welcome) and (Step <= Step::SyncOptions);
        NextEnabled := Step < Step::SyncOptions;
        FinishEnabled := (Step = Step::SyncOptions);
        NoContactsToSync := TempSyncContacts.Count() = 0;
    end;



    procedure PopulateFolderOptions(var TempFolder: Record "Contact Sync Folder" temporary)
    begin
        // Clear existing folders
        TempFolder.Reset();
        TempFolder.DeleteAll();
        NextEntryNo := 0;
    end;

    local procedure GetSyncToBCCount(): Integer
    var
        TempQueue: Record "Contact Sync Queue" temporary;
    begin
        TempQueue.Copy(TempSyncContacts, true);
        TempQueue.SetRange("Sync Direction", 1);
        exit(TempQueue.Count());
    end;

    local procedure GetSyncToM365Count(): Integer
    var
        TempQueue: Record "Contact Sync Queue" temporary;
    begin
        TempQueue.Copy(TempSyncContacts, true);
        TempQueue.SetRange("Sync Direction", 0);
        exit(TempQueue.Count());
    end;

    procedure AddFolderOption(var TempFolder: Record "Contact Sync Folder" temporary; FolderId: Text; DisplayName: Text)
    begin
        NextEntryNo += 1;
        TempFolder."Entry No." := NextEntryNo;
        TempFolder."Folder ID" := CopyStr(FolderId, 1, 2048);
        TempFolder."Display Name" := CopyStr(DisplayName, 1, 250);
        TempFolder.Insert();
    end;

    procedure GetSelectedFolderId(): Text
    begin
        exit(SelectedFolderId);
    end;

    local procedure GetContactsToAddOutlookLabel(): Text
    begin
        exit(StrSubstNo(ContactsToAddOutlookLbl, GetSyncToM365Count()));
    end;

    local procedure GetContactsToAddBCLabel(): Text
    begin
        exit(StrSubstNo(ContactsToAddBCLbl, GetSyncToBCCount()));
    end;

    local procedure GetSyncTimeLabel(): Text
    begin
        exit(StrSubstNo(SyncTimeLbl, SyncTimeText));
    end;

    local procedure GetContactsSentToM365Label(): Text
    begin
        exit(StrSubstNo(ContactsSentToM365Lbl, ContactsSentToM365Count));
    end;

    local procedure GetContactsSentToBCLabel(): Text
    begin
        exit(StrSubstNo(ContactsSentToBCLbl, ContactsSentToBCCount));
    end;

    local procedure GetContactsFailedLabel(): Text
    begin
        exit(StrSubstNo(ContactsFailedLbl, ContactsFailedCount));
    end;

    var
        TempSyncContacts: Record "Contact Sync Queue" temporary;
        TempSyncFolder: Record "Contact Sync Folder" temporary;
        PreviousFolderName: Text;
        SelectedFolderId: Text;
        SelectedFolderName: Text;
        NextEntryNo: Integer;
        FolderName: Text;
        Step: Option Welcome,ContactFilter,SyncOptions,Finish;
        AccessToken: SecretText;
        ContactFilterText: Text;
        WelcomeTextTxt: Text;
        SyncTimeText: Text;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        NoContactsToSync: Boolean;
        FullSyncOption: Boolean;
        NewLineChar: Char;
        Deltalink: Text;
        SyncDirection: Enum "ContactSyncDirection";
        ContactsSentToM365Count: Integer;
        ContactsSentToBCCount: Integer;
        ContactsFailedCount: Integer;
        WelcomeTextLbl: Label 'This guide will help you synchronize contacts from Business Central, with your contacts stored in Microsoft 365. \\This makes business contacts easily reachable from Microsoft Teams and Outlook apps on your desktop or mobile devices.\\Choose Next to continue.';
        ErrorObtainingTokenMsg: Label 'There was an error obtaining the access token. Try contacting your administrator.';
        ErrTelTxt: Label 'Empty access token for Contact Synch encountered', Locked = true;
        ErrorSelectFolderMsg: Label 'Please select a contact folder before proceeding.';
        ErrorFolderEmptyMsg: Label 'Folder cannot be empty. Please select a folder using lookup.';
        PreviewTextLbl: Label 'Choose Next to preview which contacts will be synchronized.';
        ErrorInvalidFolderMsg: Label 'Please select a valid folder from the list.';
        TotalRecordsMessageLbl: Label 'Total records matching the filter: %1', Comment = '%1 = Number of records';
        NoFolderMsg: Label 'No contact folders were found. A default folder will be created.', Locked = true;
        CategoryLbl: Label 'Contact Sync', Locked = true;
        CategoryTok: Label 'Category', Locked = true;
        SyncCountsTelLbl: Label 'Sync counts - BC: %1, M365: %2', Locked = true;
        NoContactsToSyncTelLbl: Label 'No contacts to sync', Locked = true;
        NoContactsBCToM365TelLbl: Label 'No contacts available for BC to M365 sync', Locked = true;
        StartingSyncTelLbl: Label 'Starting sync - Direction: %1', Locked = true;
        SyncCompletedTelLbl: Label 'Sync completed in %1', Locked = true;
        SyncResultsTelLbl: Label 'Sync results - M365: %1, BC: %2, Failed: %3', Locked = true;
        NoSyncMsg: Label 'No contacts to synchronize.';
        FailedSyncLbl: Label 'Failed Synchronizations';
        SyncedAtTxt: Label 'synchronized at';
        NoSyncFoundTxt: Label 'No previous synchronization found for the selected folder.';
        CaptionToSyncBCTxt: Label 'Contacts to Sync to Business Central';
        CaptionToSyncO365Txt: Label 'Contacts to Sync to Microsoft 365';
        ContactsToAddOutlookLbl: Label 'Contacts to add to Outlook: %1', Comment = '%1 = a number';
        ContactsToAddBCLbl: Label 'Contacts to add to Business Central: %1', Comment = '%1 = a number';
        SyncTimeLbl: Label 'Synchronization time: %1', Comment = '%1 = time duration';
        ContactsSentToM365Lbl: Label 'Contacts sent to Outlook and Teams: %1', Comment = '%1 = a number';
        ContactsSentToBCLbl: Label 'Contacts sent to Business Central: %1', Comment = '%1 = a number';
        ContactsFailedLbl: Label 'Contacts failed to synchronize: %1', Comment = '%1 = a number';
        ReadyTextTxt: Text;
        DisclaimerLbl: Label 'Updating Business Central will copy all contacts from the selected Outlook or Teams folder and make them visible to other Business Central users. This may include any personal contacts stored in that folder. Do you want to continue?';
        SyncAcknowledgementTelTxt: Label 'User acknowledged disclaimer for sync direction: Full Sync', Locked = true;
}
