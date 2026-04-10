namespace System.Security.AccessControl;

/// <summary>
/// Specifies the rank of a permission.
/// The higher the rank (value) is, the more restrictive the persmission is.
/// </summary>
enum 9002 Permission
{
    Extensible = false;

    /// <summary>
    /// Denotes that the permission is missing.
    /// </summary>
    value(0; None)
    {
        Caption = ' ';
    }

    /// <summary>
    /// Denotes that the permission is Indirect.
    /// </summary>
    value(10; Indirect)
    {
        Caption = 'Indirect';
    }

    /// <summary>
    /// Denotes that the permission is Direct.
    /// </summary>
    value(20; Direct)
    {
        Caption = 'Yes';
    }
}