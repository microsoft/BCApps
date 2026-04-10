namespace System.Security.AccessControl;

using Microsoft.EServices.EDocument;

permissionset 9195 "OCR - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'OCR Service Setup';

    Permissions = tabledata "OCR Service Document Template" = RIMD,
                  tabledata "OCR Service Setup" = RIMD;
}
