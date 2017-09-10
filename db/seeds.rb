contact = Contact.create(first_name: "Abraham", last_name: "Lincoln", phone: "555-555-5551",
                         email: "abraham_lincoln@example.com")
contact.notes.create(note_date: "2017-12-1", content: "Note to Abraham")
contact.notes.create(note_date: "2017-12-2", content: "Second Note to Abraham")

contact = Contact.create(first_name: "Herbert", last_name: "Hoover", phone: "555-555-5552",
                         email: "herbert_hoover@example.com")
contact.notes.create(note_date: "2018-2-1", content: "Note to Herbert")
contact.notes.create(note_date: "2018-2-2", content: "Second Note to Herbert")

