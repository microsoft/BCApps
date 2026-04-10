namespace System.Integration;

using System.Environment;
using System.Environment.Configuration;
using System.Reflection;

page 810 "Web Services"
{
    AdditionalSearchTerms = 'odata,soap';
    ApplicationArea = Basic, Suite;
    Caption = 'Web Services';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Web Service Aggregate";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1102601000)
            {
                ShowCaption = false;
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the ID of the object.';
                    ValuesAllowed = Codeunit, Page, Query;
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    TableRelation = AllObj."Object ID" where("Object Type" = field("Object Type"));
                    ToolTip = 'Specifies the ID of the object.';
                }
                field(ObjectName; WebServiceManagement.GetObjectCaption(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the object that will be exposed to the web service.';
                }
                field("Service Name"; Rec."Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the service.';
                }
                field("All Tenants"; Rec."All Tenants")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsWebServiceWriteable;
                    Enabled = IsWebServiceWriteable;
                    ToolTip = 'Specifies that the service is available to all tenants.';
                }
                field(ExcludeFieldsOutsideRepeater; Rec.ExcludeFieldsOutsideRepeater)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies whether fields outside the repeater on the page are included in the eTag calculation.';
                }
                field(ExcludeNonEditableFlowFields; Rec.ExcludeNonEditableFlowFields)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies whether non-editable FlowFields on the page are included in the eTag calculation. Note that FlowFields can interfere with publishing changes.';
                }
                field(Published; Rec.Published)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the web service is published. A published web service is available on the Business Central Server computer that you were connected to when you published. The web service is available across all Business Central Server instances running on the server computer.';
                }
                field(ODataV4Url; WebServiceManagement.GetWebServiceUrl(Rec, ClientType::ODataV4))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OData V4 URL';
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL that is generated for the web service. You can test the web service immediately by choosing the link in the field.';
                }
                field(SOAPUrl; WebServiceManagement.GetWebServiceUrl(Rec, ClientType::SOAP))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SOAP URL';
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL that is generated for the web service. You can test the web service immediately by choosing the link in the field.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("<Reload>")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reload';
                Image = Refresh;
                ToolTip = 'Update the window with the latest information.';

                trigger OnAction()
                begin
                    Reload();
                end;
            }
            action("Create Data Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Data Set';
                Image = AddAction;
                RunObject = Page "OData Setup Wizard";
                ToolTip = 'Launches wizard to create data sets that can be used for building reports in Excel, Power BI or any other reporting tool that works with an OData data source.';
            }
        }
        area(Processing)
        {
            action(DownloadODataMetadataDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Metadata Document';
                Image = ElectronicDoc;
                ToolTip = 'Downloads the OData V4 metadata document for the Business Central Web Services (does not include the metadata for API pages).';
                Visible = IsSaas;

                trigger OnAction()
                var
                    ODataUtility: Codeunit ODataUtility;
                begin
                    ODataUtility.DownloadODataMetadataDocument();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("<Reload>_Promoted"; "<Reload>")
                {
                }
                actionref(DownloadODataMetadataDocument_Promoted; DownloadODataMetadataDocument)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        IsSaas := EnvironmentInformation.IsSaaS();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."All Tenants" := IsWebServiceWriteable;
    end;

    trigger OnOpenPage()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        WebService: Record "Web Service";
        MyNotification: Record "My Notifications";
        WebserviceNotificationMgt: Codeunit "Webservice Notification Mgt.";
    begin
        if WebService.WritePermission() then
            IsWebServiceWriteable := true;
        WebserviceNotificationMgt.WebServiceAPINotificationDefault(true);
        if MyNotification.IsEnabled(WebserviceNotificationMgt.WebServiceAPINotificationId()) then
            WebserviceNotificationMgt.WebServiceAPINotificationShow(WebServcieAPINotification);

        Reload();
    end;

    var
        EnvironmentInformation: Codeunit "Environment Information";
        WebServiceManagement: Codeunit "Web Service Management";
        WebServcieAPINotification: Notification;
        ClientType: Enum "Client Type";
        IsWebServiceWriteable: Boolean;
        IsSaas: Boolean;

    procedure Reload()
    begin
        WebServiceManagement.LoadRecords(Rec);
    end;
}

