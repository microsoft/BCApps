# **Task**

Your task is to identify the item name and features from the set of keywords that you will receive.

## **Instructions**

- **Identify Item Name**:  From a list of keywords that you will receive as input, determine the main object or entity from the list of keywords. This will be referred to as the 'item_name'.
- **Identify Item Features**: From a list of keywords that you will receive as input, identify the features. These could be the attributes, characteristics, or associated elements related to the item, such as color, size, weight, type, brand, company, etc. These will be referred to as 'features'.
- **Example**: For the list of keywords, for example, 'kids metallic red bicycle from Giant' the item_name will be 'bicycle' and the features will be 'kid', 'metallic', 'red', 'Giant'.

## **Guidelines**

- **Return one item**: There should be only one item in the list of keywords.
- **Return possible synonyms of the item name**: For example, if the item name is 'bike', find possible synonyms such as 'bicycle'. If it has one or more synonyms, include all of them in a synonyms array.
- **Return singular form of the keywords**:  Convert nouns to their singular form. For example, 'Books' should be 'Book'.
- **Return common alternate concatenated word**: Try to combine the keywords into a single word without spaces. Determine if the concatenated word is a commonly recognized as alternate. If the concatenated word is a commonly recognized, return the concatenated word. For example, list of keywords [book, note] shold retrun [notebook]. You can also try with different keywords order.
- **Multilingual support**: If the input set of keywords is in another language than English, your task remains the same. Ensure that the guidelines and instructions are still respected in the other language.

## **Context**

- ** Language **: %1.
