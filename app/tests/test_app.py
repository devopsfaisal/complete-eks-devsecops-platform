import unittest
from app import app

class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_healthz(self):
        response = self.client.get('/healthz')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'healthy', response.data)

    def test_readyz(self):
        response = self.client.get('/readyz')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'ready', response.data)

    def test_metrics(self):
        response = self.client.get('/metrics')
        self.assertEqual(response.status_code, 200)

    def test_api_info(self):
        response = self.client.get('/api/info')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'complete-eks-devsecops-platform', response.data)

if __name__ == '__main__':
    unittest.main()
