router.post('/login', async (req, res) => {
    console.log('Login Request:', req.body);  // Log the incoming request body

    const { email, password } = req.body;

    // Validate email format
    if (!validateEmail(email)) {
        return res.status(400).send('Invalid email format');
    }

    try {
        const user = await User.findOne({ email });
        if (!user) {
            console.log('User not found for email:', email);  // Log user not found
            return res.status(400).send('User not found');
        }

        // Log the stored hashed password from the database
        console.log('Stored password (hashed):', user.password);

        // Log the entered password (for debugging)
        console.log('Entered password:', password);

        // Compare the entered password with the stored hashed password
        const validPassword = await bcrypt.compare(password, user.password);  // Compare passwords
        console.log('Password comparison result:', validPassword);  // Log the comparison result

        if (!validPassword) {
            console.log('Invalid password for email:', email);  // Log invalid password
            return res.status(400).send('Invalid password');
        }

        // Generate JWT token for the user
        const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });

        res.status(200).json({
            message: 'Login successful',
            token,  // Send the token to the frontend for authorization
            user: { name: user.name, email: user.email, role: user.role, isVerified: user.isVerified },
        });
    } catch (error) {
        console.error('Error during login:', error);  // Log any errors
        res.status(500).send('Error logging in: ' + error.message);
    }
});