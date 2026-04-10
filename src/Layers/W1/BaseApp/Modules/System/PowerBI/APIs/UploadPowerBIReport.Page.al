namespace System.Integration.PowerBI;

using System.IO;
using System.Utilities;

/// <summary>
/// Allows users to upload report files to Business Central, which will automatically deploy them to Power BI.
/// </summary>
page 6320 "Upload Power BI Report"
{
    Caption = 'Upload Power BI Report';
    PageType = NavigatePage;
    SourceTable = "Power BI Customer Reports";

    layout
    {
        area(content)
        {
            field(FileName; FileName)
            {
                ApplicationArea = All;
                AssistEdit = true;
                Caption = 'File';
                Editable = false;
                ShowMandatory = true;
                ToolTip = 'Specifies File Name';

                trigger OnAssistEdit()
                var
                    TempFileName: Text;
                begin
                    // Event handler for the ellipsis button that opens the file selection dialog.
                    TempFileName := FileManagement.BLOBImportWithFilter(TempBlob, FileDialogTxt, '', FileFilterTxt, ExtFilterTxt);

                    if TempFileName = '' then
                        // User clicked Cancel in the file selection dialog.
                        exit;

                    FileName := TempFileName;

                    if ReportName = '' then begin
                        ReportName := CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, 200);
                        IsFileLoaded := true;
                    end;
                end;
            }
            field(ReportName; ReportName)
            {
                ApplicationArea = All;
                Caption = 'Report Name';
                Editable = IsFileLoaded;
                ShowMandatory = true;
                ToolTip = 'Specifies Report Name';
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Upload Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload Report';
                Image = Import;
                InFooterBar = true;
                Visible = true;

                trigger OnAction()
                var
                    PowerBICustomerReports: Record "Power BI Customer Reports";
                    RecordRef: RecordRef;
                begin
                    if FileName = '' then
                        Error(FileNameErr);

                    if ReportName = '' then
                        Error(ReportNameErr);

                    PowerBICustomerReports.SetFilter(Name, ReportName);
                    if not PowerBICustomerReports.IsEmpty() then
                        Error(BlobNameErr);

                    PowerBICustomerReports.Reset();
                    if PowerBICustomerReports.Count() >= MaxReportLimit then
                        Error(TableLimitMsg);

                    PowerBICustomerReports.Init();
                    PowerBICustomerReports.Id := CreateGuid();
                    PowerBICustomerReports.Name := ReportName;
                    RecordRef.GetTable(PowerBICustomerReports);
                    TempBlob.ToRecordRef(RecordRef, PowerBICustomerReports.FieldNo("Blob File"));
                    RecordRef.SetTable(PowerBICustomerReports);
                    PowerBICustomerReports.Version := 1;
                    PowerBICustomerReports.Insert();

                    Commit();

                    FileName := '';
                    ReportName := '';

                    IsFileLoaded := false;
                    CurrPage.Update(false);
                    Message(UploadMsg);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        MaxReportLimit := 20;
    end;

    trigger OnOpenPage()
    begin
        if not PowerBIServiceMgt.IsUserAdminForPowerBI(UserSecurityId()) then
            Error(PermissionErr);

        if not PowerBIServiceMgt.IsUserReadyForPowerBI() then
            Error(NotReadyErr);
    end;

    trigger OnClosePage()
    begin
        if PowerBIReportSynchronizer.UserNeedsToSynchronize('') then
            PowerBIServiceMgt.SynchronizeReportsInBackground('');
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
        FileManagement: Codeunit "File Management";
        ReportNameErr: Label 'You must enter a report name.';
        FileNameErr: Label 'You must enter a file name.';
        NotReadyErr: Label 'The Power BI Service is currently unavailable.';
        TableLimitMsg: Label 'The Customer Report table is full. Remove a report and try again.';
        BlobNameErr: Label 'A blob with this name already exists.';
        UploadMsg: Label 'The report has been added for deployment. Once deployed, it will appear in the select reports list.';
        PermissionErr: Label 'User does not have permissions to operate this page.';
        FileDialogTxt: Label 'Select a PBIX report file.';
        FileFilterTxt: Label 'Power BI Files(*.pbix)|*.pbix';
        ExtFilterTxt: Label 'pbix', Locked = true;
        FileName: Text;
        ReportName: Text[200];
        IsFileLoaded: Boolean;
        MaxReportLimit: Integer;

}

