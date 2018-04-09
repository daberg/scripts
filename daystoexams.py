from datetime import date
from datetime import datetime

print("Countdown to exam session")

remaining = (date(2018,6,18) - datetime.now().date()).days

if remaining < 0:
    print("  the exam session has started already!")
    exit

elapsed = (datetime.now().date() - date(2018,2,26)).days

elapsed_weeks = round(elapsed / 7, 1)
remaining_weeks = round(remaining / 7, 1)

total = remaining + elapsed
remaining_perc = round(remaining / total * 100, 1)
elapsed_perc = round(elapsed / total * 100, 1)

print("  elapsed:\t" + str(elapsed) + " days\t(" + str(elapsed_weeks) + " weeks)\t(" + str(elapsed_perc) + "%)")
print("  remaining:\t" + str(remaining) + " days\t(" + str(remaining_weeks) + " weeks)\t(" + str(remaining_perc) + "%)")
