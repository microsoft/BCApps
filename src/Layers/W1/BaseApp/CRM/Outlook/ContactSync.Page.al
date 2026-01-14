namespace Microsoft.CRM.Outlook;

using Microsoft.CRM.Contact;
using System.Environment.Configuration;

page 7100 "Contact Sync"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    Caption = 'Microsoft 365 Contact Sync Wizard';

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
                    }
                }
            }

            group(Step2)
            {
                Caption = 'Authentication';
                Visible = Step = Step::Authentication;

                group(AuthGroup)
                {
                    Caption = '';
                    InstructionalText = 'Click on Next to authenticate with Microsoft 365 and retrieve contact folders.';
                }
            }

            group(Step3)
            {
                Caption = 'Contact Filter';
                Visible = Step = Step::ContactFilter;

                group(ContactFilterGroup)
                {
                    Caption = '';
                    InstructionalText = 'Select the Contact Filter to determine which contacts to synchronize.';

                    field(ContactFilter; ContactFilterText)
                    {
                        ApplicationArea = All;
                        Caption = 'Contact Filter';
                        Editable = false;
                        ToolTip = 'Specify a filter for contacts to be processed (e.g., Company Name, City). Leave blank to process all contacts.';

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
                        Caption = 'Selected Folder';
                        ToolTip = 'The selected contact folder to synchronize';
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

                }

            }

            group(Step4)
            {
                Caption = 'Ready to Sync';
                Visible = Step = Step::Ready;

                group(ReadyGroup)
                {
                    Caption = '';
                    InstructionalText = '';

                    field(ReadyText; ReadyTextTxt)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }

            group(Step6)
            {
                Caption = 'Synchronize Contacts';
                Visible = Step = Step::SyncOptions;

                group(SyncOptionsGroup)
                {
                    Caption = '';
                    InstructionalText = 'We have found some contacts to synchronize. You can view the contacts queued for synchronization below and Click Finish to start the synchronization process.';

                    field(SyncToBCButton; 'Preview contacts queued for sync with Business Central (' + Format(GetSyncToBCCount()) + ')')
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

                    field(SyncToM365Button; 'Preview contacts queued for sync with Microsoft 365 (' + Format(GetSyncToM365Count()) + ')')
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
                            TempFilteredQueue.SetRange("Sync Direction", 0);
                            SyncQueueDialog.SetData(TempFilteredQueue);
                            caption := CaptionToSyncO365Txt;
                            SyncQueueDialog.setCaption(caption);
                            SyncQueueDialog.RunModal();
                        end;
                    }
                }
            }

            group(Step7)
            {
                Caption = 'Completed';
                Visible = Step = Step::Finish;

                group(FinishGroupFinal)
                {
                    Caption = '';
                    InstructionalText = 'The contact synchronization has been completed successfully. you can close this wizard now.';
                    Visible = not NoContactsToSync;
                }

                group(FinishGroupFinalNosync)
                {
                    Caption = '';
                    InstructionalText = 'No contacts available to synchronize. you can close this wizard now.';
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
                    if Step = Step::Welcome then
                        O365GraphAuth.GetAccessToken(AccessToken);
                    if Step = Step::Authentication then begin
                        if AccessToken.IsEmpty() then begin
                            Session.LogMessage('0000QU2', ErrTelTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            Error(ErrorObtainingTokenMsg);
                        end;
                        // Populate folder options
                        PopulateFolderOptions(TempSyncFolder);
                        GraphMgt.GetContactFolders(AccessToken, TempSyncFolder);
                        if (TempSyncFolder.Count() = 0) then begin
                            Session.LogMessage('0000QU3', NoFolderMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            GraphMgt.CreateFolderinO365(AccessToken, TempSyncFolder, FolderName);
                        end;
                        if (SelectedFolderName = '') and (TempSyncFolder.FindFirst()) then begin
                            SelectedFolderId := TempSyncFolder."Folder ID";
                            SelectedFolderName := TempSyncFolder."Display Name";
                            PreviousFolderName := SelectedFolderName;
                        end;

                    end;
                    if Step = Step::ContactFilter then
                        if SelectedFolderId = '' then
                            Error(ErrorSelectFolderMsg);
                    if Step = Step::Ready then begin
                        // Fetch contacts when moving from Ready step
                        TempSyncContacts.DeleteAll();
                        GraphMgt.GetContacts(AccessToken, TempSyncContacts, ContactFilterText, SelectedFolderId);
                    end;

                    GoToStep(Step + 1);
                end;
            }

            action(ActionFetch)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Image = Approve;
                InFooterBar = true;
                Enabled = FinishEnabled;

                trigger OnAction()
                var
                    SyncProcessor: Codeunit "Contact Sync Processor";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    case Step of
                        Step::SyncOptions:
                            begin
                                // Process bidirectional sync with the queued contact
                                if TempSyncContacts.Count() = 0 then
                                    Message(NoSyncMsg)
                                else
                                    SyncProcessor.ProcessBidirectionalSync(TempSyncContacts, accessToken);
                                GoToStep(Step::Finish);
                            end;
                        Step::Finish:
                            begin
                                GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Contact Sync");
                                CurrPage.Close();
                            end;
                    end;
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
        ReadyTextTxt := ReadyDefaultTextLbl + NewLineChar;
        UpdateControls();
    end;

    local procedure GoToStep(NewStep: Option)
    begin
        Step := NewStep;
        UpdateControls();
    end;


    local procedure UpdateControls()
    begin
        BackEnabled := (Step > Step::Welcome) and (Step <= Step::SyncOptions);
        NextEnabled := Step < Step::SyncOptions;
        FinishEnabled := (Step = Step::Finish) or (Step = Step::SyncOptions);
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

    var
        TempSyncContacts: Record "Contact Sync Queue" temporary;
        TempSyncFolder: Record "Contact Sync Folder" temporary;
        PreviousFolderName: Text;
        SelectedFolderId: Text;
        SelectedFolderName: Text;
        NextEntryNo: Integer;
        FolderName: Text;
        Step: Option Welcome,Authentication,ContactFilter,Ready,SyncOptions,Finish;
        AccessToken: SecretText;
        ContactFilterText: Text;
        WelcomeTextTxt: Text;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        NoContactsToSync: Boolean;
        NewLineChar: Char;
        ReadyTextTxt: Text;
        WelcomeTextLbl: Label 'Welcome to the Microsoft 365 Contact Sync Wizard.\\This wizard will guide you through the process of syncing your Microsoft 365 contacts to Business Central.\\Click Next to continue.';
        ReadyDefaultTextLbl: Label 'All settings are configured. \\Click next to preview the list of contacts to be synchronized.';
        ErrorObtainingTokenMsg: Label 'There was an error obtaining the access token. Try contacting your administrator.';
        ErrTelTxt: Label 'Empty access token for Contact Synch encountered', Locked = true;
        ErrorSelectFolderMsg: Label 'Please select a contact folder before proceeding.';
        ErrorFolderEmptyMsg: Label 'Folder cannot be empty. Please select a folder using lookup.';
        ErrorInvalidFolderMsg: Label 'Please select a valid folder from the list.';
        TotalRecordsMessageLbl: Label 'Total records matching the filter: %1', Comment = '%1 = Number of records';
        NoFolderMsg: Label 'No contact folders were found. A default folder will be created.', Locked = true;
        CategoryLbl: Label 'Contact Sync', Locked = true;
        NoSyncMsg: Label 'No contacts to synchronize.';
        CaptionToSyncBCTxt: Label 'Contacts to Sync to Business Central';
        CaptionToSyncO365Txt: Label 'Contacts to Sync to Microsoft 365';
}
