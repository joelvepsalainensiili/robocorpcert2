*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${SAVE_FOLDER} =                ${EXECDIR}${/}save_folder
${CSV_FILEPATH} =               ${SAVE_FOLDER}${/}orders.csv
${PDF_SAVE_FOLDER} =            ${SAVE_FOLDER}${/}receipts
${CSV_URL} =                    https://robotsparebinindustries.com/orders.csv
${ORDER_URL} =                  https://robotsparebinindustries.com/#/robot-order
${CHROME_OPTIONS} =             {"prompt_for_download": "false"}
${DEFAULT_RETRY_AMOUNT} =       5x
${DEFAULT_RETRY_INTERVAL} =     0.5 sec
${MODAL_OK_BUTTON} =            //div[@class="modal-body"]//button[text()="OK"]
${HEAD_LIST} =                  //select[@id="head"]
${LEG_INPUT} =                  //div[@class="form-group"]/label[text()="3. Legs:"]/following-sibling::input
${ADDRESS_INPUT} =              //div[@class="form-group"]/input[@placeholder="Shipping address"]
${SUBMIT_ORDER_BUTTON} =        //button[@id="order"]
${RECEIPT_ELEMENT} =            //div[@id="receipt"]
${ORDER_ANOTHER_BUTTON} =       //button[@id="order-another"]


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    [Documentation]    Order all robots defined in csv
    [Tags]    order
    Download Orders CSV
    Open Order List Page
    ${orders} =    Get Orders
    FOR    ${row}    IN    @{orders}
        Log To Console    ${row}
        Order Robot    ${row}[Order number]    ${row}[Head]    ${row}[Body]    ${row}[Legs]    ${row}[Address]
    END
    [Teardown]    Close Browser

Create zip file of all order receipts
    [Documentation]    All ordered robot receipts gets zipped in order to be archived properly
    [Tags]    zipper
    ${receipts} =    Find All Order Receipts
    ${zip_filepath} =    Create Zip From PDF Files    ${receipts}
    Log To Console    ${zip_filepath}


*** Keywords ***
Download Orders CSV
    RPA.HTTP.Download    ${CSV_URL}    overwrite=${TRUE}    target_file=${CSV_FILEPATH}

Get Orders
    ${orders} =    RPA.Tables.Read table from CSV    ${CSV_FILEPATH}
    RETURN    ${orders}

Open Order List Page
    Open Chrome Browser    ${ORDER_URL}
    Close The Annoying Modal If Visible

Close The Annoying Modal If Visible
    Location Should Be    ${ORDER_URL}
    Click Element If Visible    ${MODAL_OK_BUTTON}

Order Robot
    [Arguments]    ${order_number}    ${head_index}    ${body_index}    ${leg_amount}    ${address}
    Fill The Form    ${head_index}    ${body_index}    ${leg_amount}    ${address}
    Wait Until Keyword Succeeds    ${DEFAULT_RETRY_AMOUNT}    ${DEFAULT_RETRY_INTERVAL}    Submit Robot Order
    ${pdf_save_path} =    Store Receipt As PDF    ${order_number}
    Return To Order Another Robot
    RETURN    ${pdf_save_path}

Fill The Form
    [Arguments]    ${head_index}    ${body_index}    ${leg_amount}    ${address}
    Wait Until Keyword Succeeds    ${DEFAULT_RETRY_AMOUNT}    ${DEFAULT_RETRY_INTERVAL}    Select Head    ${head_index}
    Wait Until Keyword Succeeds    ${DEFAULT_RETRY_AMOUNT}    ${DEFAULT_RETRY_INTERVAL}    Select Body    ${body_index}
    Wait Until Keyword Succeeds    ${DEFAULT_RETRY_AMOUNT}    ${DEFAULT_RETRY_INTERVAL}    Input Legs    ${leg_amount}
    Wait Until Keyword Succeeds    ${DEFAULT_RETRY_AMOUNT}    ${DEFAULT_RETRY_INTERVAL}    Input Address    ${address}

Select Head
    [Arguments]    ${head_index}
    Select From List By Index    ${HEAD_LIST}    ${head_index}

Select Body
    [Arguments]    ${body_index}
    Click Element    //label[@for="body"]/following-sibling::div[@class="stacked"]//input[@id="id-body-${body_index}"]

Input Legs
    [Arguments]    ${leg_amount}
    Input Text    ${LEG_INPUT}    ${leg_amount}

Input Address
    [Arguments]    ${address}
    Input Text    ${ADDRESS_INPUT}    ${address}

Submit Robot Order
    Click Button    ${SUBMIT_ORDER_BUTTON}
    Wait For Receipt

Wait For Receipt
    Wait Until Element Is Visible    ${RECEIPT_ELEMENT}

Return To Order Another Robot
    Wait Until Element Is Visible    ${ORDER_ANOTHER_BUTTON}
    Click Button    ${ORDER_ANOTHER_BUTTON}
    Close The Annoying Modal If Visible

Store Receipt As PDF
    [Arguments]    ${order_number}
    Wait For Receipt
    ${image_save_path} =    Set Variable    ${PDF_SAVE_FOLDER}${/}${order_number}.png
    ${pdf_save_path} =    Set Variable    ${PDF_SAVE_FOLDER}${/}${order_number}.pdf
    Capture Element Screenshot    ${RECEIPT_ELEMENT}    ${image_save_path}
    ${screenshot_file} =    Create List    ${image_save_path}
    Embed Receipt Screenshot To Pdf    ${screenshot_file}    ${pdf_save_path}
    RETURN    ${pdf_save_path}

Embed Receipt Screenshot To Pdf
    [Arguments]    ${screenshot_file}    ${save_document}
    Add Files To Pdf    ${screenshot_file}    ${save_document}
    RETURN    ${save_document}

Find All Order Receipts
    ${order_receipts} =    Find Files    ${PDF_SAVE_FOLDER}${/}*.pdf
    RETURN    ${order_receipts}

Create Zip From PDF Files
    [Arguments]    ${pdf_files}
    ${zip_file_name} =    Set Variable    ${SAVE_FOLDER}${/}receipts.zip
    Archive Folder With Zip    ${PDF_SAVE_FOLDER}    ${zip_file_name}    ${False}    *.pdf
    RETURN    ${zip_file_name}
