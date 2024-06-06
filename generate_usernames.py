def generate_usernames(first_name, middle_name, last_name):
    usernames = []

    # Standard username formats
    if first_name and last_name:
        usernames.append(first_name.lower())                               # First name only
        usernames.append(first_name[0].lower() + last_name.lower())        # First initial + Last name
        usernames.append(last_name.lower() + first_name[0].lower())        # Last name + First initial
        usernames.append(first_name.lower() + last_name.lower())           # First name + Last name
        usernames.append(last_name.lower() + first_name.lower())           # Last name + First name
        usernames.append(last_name.lower() + '.' + first_name.lower())     # Last name + '.' + First name
        usernames.append(last_name.lower() + '_' + first_name.lower())     # Last name + '_' + First name

    if middle_name and last_name:
        usernames.append(middle_name.lower() + last_name.lower())          # Middle name + Last name
        usernames.append(last_name.lower() + middle_name.lower())          # Last name + Middle name
        usernames.append(last_name.lower() + '.' + middle_name.lower())    # Last name + '.' + Middle name
        usernames.append(last_name.lower() + '_' + middle_name.lower())    # Last name + '_' + Middle name

    if first_name and middle_name and last_name:
        usernames.append(first_name[0].lower() + middle_name[0].lower() + last_name.lower()) # First initial + Middle initial + Last name
        usernames.append(middle_name[0].lower() + first_name[0].lower() + last_name.lower()) # Middle initial + First initial + Last name
        usernames.append(first_name.lower() + middle_name.lower() + last_name.lower())       # First name + Middle name + Last name
        usernames.append(first_name.lower() + '.' + middle_name.lower() + '.' + last_name.lower())# First name + '.' + Middle name + '.' + Last name
        usernames.append(first_name.lower() + '_' + middle_name.lower() + '_' + last_name.lower())# First name + '_' + Middle name + '_' + Last name

    return usernames

if __name__ == "__main__":
    first_name = input("Enter the first name: ").strip()
    middle_name = input("Enter the middle name: ").strip()
    last_name = input("Enter the last name: ").strip()

    usernames = generate_usernames(first_name, middle_name, last_name)

    for username in usernames:
        print(username)
