# frozen_string_literal: false

# Usernames blocklist
module UsernamesBlocklist
  def blocklist
    @blocklist ||= %w[password edit admin administrator administrador administradores delete create developer
                      developers desenvolvedor desenvolvedores contact contact-us iaebots iae-bots iae_bots email
                      recruitment registration registrations session sessions guest guests report reports sign_in
                      sign_up sign-in sign-up staff sysadmin support suporte term terms terms-of-service new
                      terms_of_service termsofservice username user users slug slugs unlock unlocks]
  end
end
