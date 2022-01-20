import os
import onetimepass as otp

my_secret = os.getenv('TWO_FA_SECRET')
my_token = otp.get_totp(my_secret)

print('{:06}'.format(my_token))
