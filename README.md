## ActiveRecord Lite
ActiveRecord Lite is a Ruby ORM inspired by Rails' ActiveRecord library. It converts rows of a table to Ruby objects of the class corresponding to that table.  
### Conventions
Following the Rails philosophy, ActiveRecord Lite favors convention over configuration, and infers which table to query based on the name of the Ruby class on which ActiveRecord Lite methods are called.  As such, it is imperative that anyone using the code follow these rules:

1. Table names should be lowercase, pluralized versions of the class they correspond to.  ie. records in the users table map to objects of class User.

2. Associations (methods that return objects  related to their receiver by a foreign key in the database) should be the lowercase, pluralized versions of the class of the objects they return.


### Features
ActiveRecord Lite provides the following features:

1. The ability to define attribute getters and setters with a single call to attribute_accessor.  Like Rails' attr_accessor, the method takes any number of symbols (names of instance variables) as arguments.

2. Basic record creation and updating (insert, save, update), table querying (find, all).

3. Searching by using the method where, which takes a params hash and return the records whose attributes match.

4. belongs_to, has_many, and has_many_through associations, which query tables determined by the association's name, and infer the primary and foreign key relationships.
