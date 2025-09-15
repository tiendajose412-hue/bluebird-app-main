class Validators {
  // Validador de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    
    return null;
  }
  
  // Validador de contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }
  
  // Validador de confirmación de contraseña
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }
  
  // 📱 NUEVO: Validador de número de teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de teléfono es requerido';
    }
    
    // Remover espacios y caracteres especiales para validación
    String cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Verificar que tenga al menos 10 dígitos (formato México)
    if (cleanPhone.length < 10) {
      return 'El número debe tener al menos 10 dígitos';
    }
    
    // Verificar que tenga máximo 15 dígitos (estándar internacional)
    if (cleanPhone.length > 15) {
      return 'El número no puede tener más de 15 dígitos';
    }
    
    // Verificar que solo contenga números y opcionalmente el símbolo +
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Formato de teléfono inválido';
    }
    
    return null;
  }
  
  // Validador de código de verificación
  static String? validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código es requerido';
    }
    
    if (value.length != 1 || !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Ingresa un número válido';
    }
    
    return null;
  }
  
  // 👤 NUEVO: Validador de nombre completo (útil para perfil)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    
    if (value.length > 50) {
      return 'El nombre no puede tener más de 50 caracteres';
    }
    
    // Verificar que solo contenga letras, espacios y algunos caracteres especiales
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ '´-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'El nombre contiene caracteres inválidos';
    }
    
    return null;
  }
  
  // 🔧 NUEVO: Validador genérico para campos requeridos
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  // 🔐 NUEVO: Validador de contraseña fuerte (opcional)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    
    // Verificar que tenga al menos una minúscula
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una letra minúscula';
    }
    
    // Verificar que tenga al menos una mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra mayúscula';
    }
    
    // Verificar que tenga al menos un número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    
    // Verificar que tenga al menos un carácter especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Debe contener al menos un carácter especial';
    }
    
    return null;
  }
  
  // 🌐 NUEVO: Validador de URL (opcional para futuras funciones)
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL es opcional en este caso
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Ingresa una URL válida';
    }
    
    return null;
  }
  
  //Validador de email 
  static String? validateEmailStrict(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Formato de correo electrónico inválido';
    }
    
    if (value.length > 254) {
      return 'El correo electrónico es demasiado largo';
    }
    
    return null;
  }
  
  // 💳 NUEVO: Validador de código postal mexicano (opcional)
  static String? validateMexicanZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código postal es requerido';
    }
    
    // Código postal mexicano: 5 dígitos
    final zipRegex = RegExp(r'^\d{5}$');
    if (!zipRegex.hasMatch(value)) {
      return 'Formato de código postal inválido (5 dígitos)';
    }
    
    return null;
  }
}