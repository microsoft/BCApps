namespace System.Security.AccessControl;

using System.Reflection;

report 8313 "Get License Permissions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './System/Permissions/LicensePermissions.rdlc';
    Caption = 'License Permissions';

    dataset
    {
        dataitem("Permission Range"; "Permission Range")
        {
            DataItemTableView = sorting("Object Type", Index);
            RequestFilterFields = "Object Type";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Permission_Range__Object_Type_; "Object Type")
            {
            }
            column(Permission_Range_From; From)
            {
            }
            column(Permission_Range__To_; "To")
            {
            }
            column(Permission_Range__Read_Permission_; "Read Permission")
            {
            }
            column(Permission_Range__Insert_Permission_; "Insert Permission")
            {
            }
            column(Permission_Range__Delete_Permission_; "Delete Permission")
            {
            }
            column(Permission_Range__Execute_Permission_; "Execute Permission")
            {
            }
            column(Permission_Range__Modify_Permission_; "Modify Permission")
            {
            }
            column(Description; Description)
            {
            }
            column(Permission_Range_Index; Index)
            {
            }
            column(License_PermissionsCaption; License_PermissionsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Permission_Range__Object_Type_Caption; FieldCaption("Object Type"))
            {
            }
            column(Permission_Range_FromCaption; FieldCaption(From))
            {
            }
            column(Permission_Range__To_Caption; FieldCaption("To"))
            {
            }
            column(Permission_Range__Read_Permission_Caption; FieldCaption("Read Permission"))
            {
            }
            column(Permission_Range__Insert_Permission_Caption; FieldCaption("Insert Permission"))
            {
            }
            column(Permission_Range__Delete_Permission_Caption; FieldCaption("Delete Permission"))
            {
            }
            column(Permission_Range__Execute_Permission_Caption; FieldCaption("Execute Permission"))
            {
            }
            column(Permission_Range__Modify_Permission_Caption; FieldCaption("Modify Permission"))
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Description := '';
                if "Object Type" = "Object Type"::System then
                    if SysObject.Get("Object Type", From) then
                        Description := SysObject."Object Name";
            end;
        }
        dataitem("License Information"; "License Information")
        {
            DataItemTableView = sorting("Line No.");
            column(USERID_Control12; UserId)
            {
            }
            column(FORMAT_TODAY_0_4__Control19; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME_Control25; COMPANYPROPERTY.DisplayName())
            {
            }
            column(SkipHeader; SkipHeader)
            {
            }
            column(License_Information_Text; Text)
            {
            }
            column(License_Information_Line_No_; "Line No.")
            {
            }

            trigger OnPreDataItem()
            begin
                SkipHeader := true;
                SkipHeader := false;
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

    var
        SysObject: Record "System Object";
        Description: Text[50];
        SkipHeader: Boolean;
        License_PermissionsCaptionLbl: Label 'License Permissions';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        DescriptionCaptionLbl: Label 'Description';
}

