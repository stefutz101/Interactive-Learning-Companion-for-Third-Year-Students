import os
import re
from ironpdf import PdfDocument, License

License.LicenseKey = "IRONSUITE.STEFAN.POENARU97.E.UVT.RO.4444-2C9ABA6B3D-CW3YJGJNNJILXM-4HJ3BX4ZDHGK-IDWN6QZ3FK2B-27HSBJALIE4V-BZQQYCLVBQKA-QR7WOEO5BWSB-Y6AYCA-T5W3AS6PHCKMUA-DEPLOYMENT.TRIAL-KHAXEJ.TRIAL.EXPIRES.23.MAY.2024"

# # Set a log path
# Logger.EnableDebugging = True
# Logger.LogFilePath = "Custom.log"
# Logger.LoggingMode = Logger.LoggingModes.All

# Directory containing PDF files
pdf_directory = "train\DB1\PDFs"

# Function to clean up extracted text
def clean_text(text):
    # Remove extra whitespace
    cleaned_text = re.sub(r'\r(?!\n)', '', text)
    return cleaned_text

# Iterate over each PDF file in the directory
for pdf_file in os.listdir(pdf_directory):
    if pdf_file.endswith(".pdf"):
        # Load the PDF document
        pdf_path = os.path.join(pdf_directory, pdf_file)
        pdf = PdfDocument.FromFile(pdf_path)

        # Extract text from the PDF document
        all_text = pdf.ExtractAllText()

        # Clean up the extracted text
        cleaned_text = clean_text(all_text)

        # Create a corresponding .txt file and save the extracted text
        txt_file_path = os.path.splitext(pdf_path)[0] + ".txt"
        with open(txt_file_path, "w", encoding="utf-8") as txt_file:
            txt_file.write(all_text)

        print(f"Text extracted from '{pdf_file}' and saved to '{txt_file_path}'")

# Load existing PDF document
#pdf = PdfDocument.FromFile("train\DB1\PDFs\db-course-01.pdf")
 
# Extract text from PDF document
#all_text = pdf.ExtractAllText()
# print(all_text)  # Prints the extracted text to the console
 
# Extract text from specific page in the document
# page_2_text = pdf.ExtractTextFromPage(1)



# pdf = PdfDocument.FromFile("./train/DB1/PDFs/db-course-01.pdf")



# all_text = pdf.ExtractAllText()  # Extracts all text from the PDF document
# print(all_text)  # Prints the extracted text to the console
