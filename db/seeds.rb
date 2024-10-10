User.create!(name: 'Hacker', 
  email: 'hacker@example.com',
  website: 'javascript://example.com/%0Aalert(1)', 
  password: Digest::MD5.hexdigest('password hasheado'))

User.create!(name: 'Victim',
  email: 'victim@example.com', 
  website: 'http://example.com', 
  password: Digest::MD5.hexdigest('password hasheado'))

User.create!(name: 'John Doe',
  email: 'john.doe@example.com', 
  website: 'http://example.com', 
  password: Digest::MD5.hexdigest('password'))

User.create!(name: 'Jenn Martins',
  email: 'jenn.martins@example.com', 
  website: 'http://example.com', 
  password: Digest::MD5.hexdigest('123456789'))
