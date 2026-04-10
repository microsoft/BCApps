namespace System.AI;

enum 2021 "Image Analysis Type"
{
    Extensible = false;
    // Docs from https://westus.dev.cognitive.microsoft.com/docs/services/computer-vision-v3-2/operations/56f91f2e778daf14a499f21b

    /// <summary>
    /// Tags - tags the image with a detailed list of words related to the image content.
    /// </summary>
    value(0; Tags)
    {
    }

    /// <summary>
    /// Faces - detects if faces are present. If present, generate coordinates, gender and age.
    /// </summary>
    value(5; Faces)
    {
    }

    /// <summary>
    /// Color - determines the accent color, dominant color, and whether an image is black and white.
    /// </summary>
    value(10; Color)
    {
    }

    /// <summary>
    /// Adult - detects if the image is pornographic in nature (depicts nudity or a sex act), or is gory (depicts extreme violence or blood). Sexually suggestive content (aka racy content) is also detected.
    /// </summary>
    value(40; Adult)
    {
    }
}