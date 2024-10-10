## Laboratorio 9: Vulnerabilidades de Seguridad Comunes en Aplicaciones Web y Móviles

En este laboratorio veremos algunas de las vulnerabilidades más comunes que han sido históricamente incorporadas a los rankings del Open Web Application Security Project (OWASP). Estas incluyen _Cross-Site Request Forgery_ (CSRF), _Cross-Site Scripting_ (XSS), _XML External Entity_ (XEE), e inyección SQL. Para demostrar estas vulnerabilidades, usaremos una aplicación web basada en Rails. Si bien se trata de una aplicación web, algunas de estas vulnerabilidades pueden estar presentes también en aplicaciones de cliente híbrido, por ejemplo, basadas en React Native.

## Ejecutar la aplicación

La aplicación web que usaremos en este laboratorio se basa en un proyecto bastante antiguo que fue desarrollado originalmente con Rails 5. Hemos actualizado las dependencias de este proyecto y creado una imagen de Docker para facilitar la ejecución. Es recomendable usar Docker y no instalar directamente sobre el sistema host, pues se requieren varias dependencias antiguas y no es recomendable instalarlas directamente.

Por el momento, la imagen disponible solamente soporta hardware x86-64.

Para instalar la imagen de Docker, los pasos son los siguientes:

```sh
docker pull claudioag/rails-vuln-demos:latest
```

Lo anterior descarga la imagen desde Docker Hub. Para ejecutarla:

```sh
docker run -p 3000:3000 claudioag/rails-vuln-demos:latest
```

Luego, puedes abrir [http://localhost:3000](http://localhost:3000) en el navegador web.

## CSRF: Ataque de Cross-Site Request Forgery

### Explotación

Un ataque CSRF utiliza un sitio malicioso para engañar a un navegador con una sesión activa en otro sitio y hacer que realice una acción no deseada.

Por ejemplo, tienes un perfil en un sitio web que requiere autenticación para editarlo; como Facebook o X. Si ese sitio web no verifica la autenticidad de las solicitudes hechas a endpoints sensibles, es posible que un atacante secuestre una solicitud y realice cambios en el perfil de la víctima.

Para explotar esto con la aplicación proporcionada, abre [http://localhost:3000/csrf_attack.html](http://localhost:3000/csrf_attack.html).

Dicha página al abrirse envía una petición a la aplicación para modificar los datos de un usuario. Deberías ver una redirección a `localhost:3000`, notificándote que la dirección de correo electrónico fue actualizada. La dirección de correo electrónico del usuario víctima, el usuario con ID 2, se cambiará de "victim@example.com" a "changed@example.com".

Esto es solo una demostración de cómo podría funcionar. Debido a los protocolos de seguridad del navegador y los valores predeterminados en otras apps, esto puede ser difícil de reproducir en una aplicación de producción real.

### Mitigación

La mitigación es relativamente sencilla si estás utilizando una aplicación como Rails. Muchos frameworks modernos, incluidos Django, Spring de Java, Rails y .NET, tienen protección CSRF integrada.

Para habilitar la protección CSRF en Rails, agrega protección contra falsificación a tu ApplicationController para proteger solicitudes sensibles. Rails no protege las solicitudes GET porque las solicitudes sensibles nunca deben enviarse como solicitudes GET.

Agrega lo siguiente a tu `ApplicationController`:


```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery, with: :exception
end
```

Agrega además el siguiente llamado a método en el elemento head de la vista:

```erb
<%= csrf_meta_tags %>
```

### Referencias

[OWASP](https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF))
[Neal Poole's Blob](https://nealpoole.com/blog/2012/03/csrf-clickjacking-and-the-role-of-x-frame-options/)  
[pentestmonkey.net](http://pentestmonkey.net/blog/csrf-xml-post-request)  
[Per-form CSRF token PR for Rails](https://github.com/rails/rails/pull/22275)

## Ataque de Cross-Site Scripting (XSS)

### Explotación

Los ataques XSS inyectan JavaScript malicioso en sitios web de confianza. XSS es fácilmente explotable si tu aplicación está mostrando o evaluando la entrada del usuario que no ha sido saneada por la aplicación.

Para los propósitos de esta demostración, nos vamos a enfocar en XSS almacenado. El XSS almacenado significa que el atacante inserta un script malicioso en tu base de datos o sistema de archivos, que se ejecutará cuando la víctima visite la página que contiene ese script.

Visita la página de perfil de "hacker" en [http://localhost:3000/users/1](http://localhost:3000/users/1) y verás una alerta cuando accedas, que proviene del nombre del usuario. La razón por la cual esto es explotable es porque estamos ejecutando `html_safe` con el string ingresado por el usuario (revisa `app/views/users/show.html.erb`). El método `html_safe`en Rails marca un string como "seguro" para ser renderizado como HTML sin escapar, permitiendo que el contenido HTML dentro de ese string se interprete directamente en el navegador.

Hay un segundo ejemplo de XSS en la vista `index` de `User` [http://localhost:3000/users](http://localhost:3000/users). Usando el esquema `javascript://`, el atacante puede ejecutar JavaScript cuando la víctima haga clic en el enlace del sitio web en la URL del perfil. La víctima puede no darse cuenta de que esta URL especialmente codificada es dañina. Hacer clic en "website" ejecutará el JavaScript después de la codificación `%0A`, que indica un salto de línea, también conocido como ir a la siguiente línea.

```
javascript://example.com/%0Aalert(1)
```

### Mitigación

Por defecto, Rails intenta proteger a los programadores de permitir la inyección XSS, pero si lo habilitas intencionadamente, Rails no puede protegerte.

Nunca ejecutes `html_safe` en strings ingresados por el usuario sin algún tipo de saneamiento primero.

Si debes permitir HTML en la entrada del usuario, utiliza una biblioteca de saneamiento como la que viene por defecto con ActiveSupport.

```erb
<%= sanitize(user.name) %>
```

Esto permitirá una lista blanca personalizable de etiquetas, pero también te protegerá de XSS al asegurarse de que la etiqueta `img` no permita el atributo `onerror`.

También puedes validar los datos proporcionados por el usuario antes de insertarlos en la base de datos.

El siguiente validador para el sitio web del usuario verifica que los únicos esquemas que nuestra aplicación permite son `http` y `https`. Cualquier sitio web con otro esquema será rechazado con un error. Siempre debes usar una biblioteca de análisis URI en lugar de una expresión regular para esto, porque es fácil equivocarse con las expresiones regulares, pero una biblioteca de análisis está ampliamente usada y probada.

```ruby
class User < ActiveRecord::Base
  WHITELISTED_URI_SCHEMES = %w( http https )

  validate :check_uri_scheme

  private
    def check_uri_scheme
      begin
        uri = URI.parse(website)
        unless WHITELISTED_URI_SCHEMES.include?(uri.scheme.downcase)
          errors.add :website, 'is not an allowed URI scheme'
        end
      rescue URI::InvalidURIError
        errors .add :website, 'is not a valid URI'
      end
    end
end
```

### Referencias

[OWASP](https://www.owasp.org/index.php/Cross-site_Scripting_(XSS))  
[OWASP Cheat Sheet](https://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet)  
[Blackhat Presentation by Eduardo Vela and David Lindsay](https://www.blackhat.com/presentations/bh-usa-09/VELANAVA/BHUSA09-VelaNava-FavoriteXSS-SLIDES.pdf)

## Ataque de XML eXternal Entity (XXE)

Una XML External Entity (XXE) es una característica de procesamiento de XML que permite a los documentos XML definir entidades que se pueden reemplazar con datos externos al documento. Las entidades externas son referencias que pueden apuntar a archivos locales, recursos remotos o incluso scripts, lo que abre la posibilidad de explotar esta característica si no se maneja de manera segura.

### Explotación

El siguiente ejemplo muestra cómo se puede utilizar una entidad externa para intentar acceder a un archivo local en el servidor, como `/etc/passwd` (un archivo típico en sistemas Unix/Linux que contiene información sobre los usuarios):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [
  <!ELEMENT foo ANY >
  <!ENTITY xxe SYSTEM "file:///etc/passwd" >
]>
<foo>&xxe;</foo>
```

Explicación:

* `DOCTYPE`: Define un tipo de documento que incluye una declaración de entidad llamada xxe.
* `ENTITY xxe SYSTEM`: Esta línea define la entidad externa `xxe`, la cual hace referencia a un archivo en el sistema (`file:///etc/passwd`).
* `&xxe;`: En el cuerpo del XML, se inserta la entidad `xxe`, que el parser intentará reemplazar con el contenido del archivo `/etc/passwd`.

Cuando un parser XML que no está protegido procesa este documento, intentará leer el archivo `/etc/passwd` y reemplazará la entidad `&xxe;` por el contenido de ese archivo, exponiéndolo al atacante si el archivo es procesado o devuelto como parte de una respuesta.

Entonces, más generalmente, si una aplicación tiene un endpoint que analiza XML, un atacante podría enviar un payload especialmente diseñado al servidor y obtener archivos sensibles. Los archivos que el atacante pueda obtener dependen en gran medida de cómo esté configurado el sistema y cómo se implementen los permisos de usuario.

Usando el archivo de payload `xxe.xml` en la raíz de este repositorio, podemos enviar una solicitud cURL al endpoint de creación de usuarios que acepta XML.

```sh
curl -X 'POST' \
     -H 'Content-Type: application/xml' \
     -d @xxe.xml \
     http://localhost:3000/users.xml
```

El payload recogerá el archivo `secrets.yml` y lo establecerá como el nombre del usuario cuando se envíe la solicitud. El archivo `secrets.yml` se insertará en la base de datos como el nombre del usuario y será devuelto al atacante.

### Mitigación

* No analices XML si no es un requisito de la aplicación.
* No uses una biblioteca que soporte reemplazo de entidades (como LibXML). Usa la biblioteca REXML, la cual no permite el reemplazo de entidades externas de manera predeterminada.
* Asegúrate de que el reemplazo de entidades esté deshabilitado. Las nuevas versiones de LibXML dificultan la habilitación del reemplazo de entidades. Tu aplicación aún puede ser vulnerable a un ataque de denegación de servicio (DoS) al usar LibXML.

```ruby
>> LibXML::XML.default_substitute_entities
>> false
```

* Si necesitas usar entidades externas, puedes usar una lista blanca para sólo permitir entidades externas conocidas.

### Referencias

[OWASP](https://www.owasp.org/index.php/XML_External_Entity_(XXE)_Processing)  
[Software Engineering Institute, Carnegie Mellon](https://www.securecoding.cert.org/confluence/display/java/IDS17-J.+Prevent+XML+External+Entity+Attacks)  
[LibXML Example](https://github.com/xml4r/libxml-ruby/blob/c46ec53c68e4552c4e6547b52e3f365c3d4d9dd0/test/c14n/given/example-5.xml)  
[SANS Hands-On XML External Entity Vulnerability Training](http://www.sans.org/reading-room/whitepapers/application/hands-on-xml-external-entity-vulnerability-training-module-34397)  
[ColeSec Security](http://colesec.inventedtheinternet.com/attacking-xml-with-xml-external-entity-injection-xxe/)

## Ataque de inyección SQL

La inyección SQL (SQL Injection, o SQLi) es un tipo de vulnerabilidad de seguridad que ocurre cuando un atacante manipula las consultas SQL que se envían a una base de datos, inyectando código malicioso a través de la entrada de datos de una aplicación. Esto permite que el atacante acceda, manipule o elimine datos de una base de datos, e incluso, en algunos casos, obtenga acceso al servidor subyacente.

La demostración de este ataque es una añadidura a la aplicación desarrollada originalmente por Eileen M. Uchiltelle (ver créditos). 

### Explotación

En una aplicación que interactúa con una base de datos, las consultas SQL son utilizadas para obtener o modificar datos. Una aplicación vulnerable a inyección SQL permite que las entradas del usuario, como formularios o URLs, se incluyan directamente en las consultas SQL sin validación o saneamiento adecuado. El atacante puede explotar esto enviando entradas maliciosas que se interpretan como parte de la consulta SQL.

Imagina que tienes una consulta SQL simple que busca un usuario por su nombre de usuario:

```sql
SELECT * FROM users WHERE username = 'usuario';
```

Si la aplicación simplemente inserta el valor que el usuario proporciona en el campo username sin verificarlo o limpiarlo, un atacante podría introducir un valor como:

```sql
' OR '1'='1
```

El código SQL resultante sería:

```sql
SELECT * FROM users WHERE username = '' OR '1'='1';
```

Esto altera la consulta original y devuelve todos los registros de la tabla users, ya que la condición `'1'='1'` siempre es verdadera. De esta forma, el atacante podría saltarse la autenticación o acceder a datos a los que no debería tener acceso.

Para realizar una inyección SQL con nuestra aplicación, puedes abrir la página de búsqueda de usuarios en [http://localhost:3000/search](http://localhost:3000/search) y buscar:

* Primero busca con una palabra clave válida para ver el resultado, busca "john".
* Ahora, vuelve a la página de búsqueda e ingresa en el campo de búsqueda lo siguiente:

```sql
' OR 1=1 UNION SELECT name, email, password as website FROM users; --
```

La inyección tiene dos partes: la primera añade `OR 1=1` para incluir todos los registros de la tabla en los resultados. La segunda parte, hace union con la selección de columnas `name`, `email` y `password` con alias `website`. Así es posible filtrar todas las contraseñas (hasheadas).

Con lo anterior verás en la página de resultados los datos de nombre, email y sitio web de los usuarios alternados con filas en donde se puede ver la contraseña hasheada de los usuarios.

Si el hashing de contraseñas es débil y/o vulnerable, los atacantes podrán recuperar contraseñas en texto plano.

### Mitigación

Hay varias prácticas que permiten robustecer la seguridad de aplicaciones frente a los ataques de tipo SQLi:

**Consultas preparadas:** Las consultas preparadas o consultas parametrizadas separan el código SQL de los datos que el usuario proporciona, evitando que los datos se interpreten como código.

Con ActiveRecord, si se quiere la flexibilidad de utilizar SQL en las consultas, es importante adoptar buenas prácticas; básicamente, evitar hacer interpolación de variables en los strings. Un antiejemplo es el siguiente:

```ruby
User.where("username = '#{username}' AND email = '#{email}'")
```

Esta forma usa directamente la interpolación de variables en strings, y evidentemente, genera una brecha de seguridad al permitir inyección de código SQL. En vez de esto, se debe utilizar lo siguiente:


```ruby
User.where("username = ? AND email = ?", username, email)
```

Al utilizar el marcador `?`, ActiveRecord automáticamente sanitiza as variables en caso que éstas pudieran contener código SQL.

La aplicación web que estamos examinando tiene dos falencias fundamentales que facilitan la inyección de código SQL (ver `app/controllers/users_controller.rb:search`):

Se está haciendo interpolación de variables directamente en el string de la consulta:
```ruby    
    query = "SELECT name, email, website FROM users WHERE name LIKE '%#{name}%'"
```
Por otro lado, se está utilizando active record para ejecutar la consulta, pero en la forma menos segura, llamando directamente al método `execute` que permite ejecutar prácticamente cualquier operación para la cual el usuario de la base de datos tiene permisos:

```ruby
ActiveRecord::Base.connection.execute(query)
```

**Uso de ORM (Object-Relational Mapping):** Un ORM como ActiveRecord (en Rails) o Sequelize (en Node.js) abstrae las consultas SQL, lo que hace más difícil que ocurra una inyección SQL si se utilizan de manera adecuada.

**Saneamiento de entradas:** Limitar los tipos de datos que los usuarios pueden ingresar y sanitizar cualquier entrada de usuario para eliminar caracteres peligrosos.

**Principio del menor privilegio:** Asegurarse de que las cuentas de base de datos utilizadas por la aplicación tengan los permisos mínimos necesarios para operar.

**Validación de entrada:** Siempre validar y limpiar los datos que provienen del usuario para asegurar que solo contengan lo que se espera.

## Créditos

Este laboratorio está basado en el proyecto original desarrollado por [Eileen M. Uchiltelle](https://github.com/eileencodes), quien parte del equipo core de Rails y del equipo de infraestructura de Shopify. El repositorio con el proyecto original está en https://github.com/eileencodes/security_examples.