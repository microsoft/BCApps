// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using System.IO;

table 138 "Unlinked Attachment"
{
    Caption = 'Unlinked Attachment';
    DataClassification = CustomerContent;

    fields
    {
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(5; "File Name"; Text[250])
        {
            Caption = 'File Name';

            trigger OnValidate()
            var
                FileManagement: Codeunit "File Management";
                Extension: Text;
            begin
                Extension := FileManagement.GetExtension("File Name");
                case LowerCase(Extension) of
                    'jpg', 'jpeg', 'bmp', 'png', 'tiff', 'tif', 'gif':
                        Type := Type::Image;
                    'pdf':
                        Type := Type::PDF;
                    'docx', 'doc':
                        Type := Type::Word;
                    'xlsx', 'xls':
                        Type := Type::Excel;
                    'pptx', 'ppt':
                        Type := Type::PowerPoint;
                    'msg':
                        Type := Type::Email;
                    'xml':
                        Type := Type::XML;
                    else
                        Type := Type::Other;
                end;
            end;
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Image,PDF,Word,Excel,PowerPoint,Email,XML,Other';
            OptionMembers = " ",Image,PDF,Word,Excel,PowerPoint,Email,XML,Other;
        }
        field(8; Content; BLOB)
        {
            Caption = 'Content';
            SubType = Bitmap;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Created Date-Time")
        {
        }
    }

    fieldgroups
    {
    }

    var
        CannotInsertWithNullSystemIdErr: Label 'Attempted to insert Unlinked Attachment with null SystemId. This is a programing error.', Locked = true;

    trigger OnInsert()
    var
        NullSystemIdErrorInfo: ErrorInfo;
    begin
        if not Rec.IsTemporary() then
            exit;

        if IsNullGuid(Rec.SystemId) then begin
            NullSystemIdErrorInfo.ErrorType := NullSystemIdErrorInfo.ErrorType::Internal;
            NullSystemIdErrorInfo.DataClassification := NullSystemIdErrorInfo.DataClassification::SystemMetadata;
            NullSystemIdErrorInfo.Verbosity := NullSystemIdErrorInfo.Verbosity::Error;
            NullSystemIdErrorInfo.Message := CannotInsertWithNullSystemIdErr;
            Error(NullSystemIdErrorInfo);
        end;

        Id := SystemId;
    end;
}

