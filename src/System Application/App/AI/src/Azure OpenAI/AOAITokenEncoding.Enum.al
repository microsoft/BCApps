namespace System.AI;

/// <summary>
/// List of encoding types for various models.
/// </summary>
enum 7771 "AOAI Token Encoding"
{
    Extensible = false;

    /// <summary>
    /// Used for the newer gpt-4/gpt-3.5-turbo/embeddings models.
    /// </summary>
    value(0; cl100k_base)
    {
        Caption = 'cl100k_base';
    }

    /// <summary>
    /// Used for codex and older text-davinci-2 models.
    /// </summary>
    value(1; p50k_base)
    {
        Caption = 'p50k_base';
    }
}