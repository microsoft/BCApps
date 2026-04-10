namespace System.AI;

using System.Text;

interface "Image Analysis Provider"
{
    Access = Internal;

    procedure IsLanguageSupported(AnalysisTypes: List of [Enum "Image Analysis Type"]; Language: Integer): Boolean

    procedure InvokeAnalysis(var JSONManagement: Codeunit "JSON Management"; BaseUrl: Text; ImageAnalysisKey: SecretText; ImagePath: Text; ImageAnalysisTypes: List of [Enum "Image Analysis Type"]; LanguageId: Integer): Boolean

    procedure IsMediaSupported(MediaID: Guid): Boolean;

    procedure GetLastError(): Text;

}