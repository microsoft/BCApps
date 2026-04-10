namespace System.AI;

/// <summary>
/// The types of Azure AI services that are available in Business Central.
/// </summary>
enum 2004 "Azure AI Service"
{
    Extensible = false;

    /// <summary>
    /// Value corresponds to an Azure Machine Learning service. 
    /// </summary>
    value(0; "Machine Learning")
    {
        Caption = 'Machine Learning';
    }

    /// <summary>
    /// Value corresponds to an Azure Computer Vision service. 
    /// </summary>
    value(1; "Computer Vision")
    {
        Caption = 'Computer Vision';
    }
}