#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <vector>
#include <chrono>

class MFSet_NoPC_NoRK
{
public:
    MFSet_NoPC_NoRK( uint32_t size ) { m_vecN.resize(size); Init(); }
    ~MFSet_NoPC_NoRK() {}
    inline void Init()
        {
            for( uint32_t it_n=0; it_n<m_vecN.size(); it_n++ )
                m_vecN[it_n].m_Parent = it_n;
        }
    inline uint32_t Find( uint32_t n ) const
        {
            uint32_t root(n);
            while ( root != m_vecN[root].m_Parent )
                root = m_vecN[root].m_Parent;
            return root;
        }
    inline void Merge( uint32_t n1, uint32_t n2 )
        {
            uint32_t root1( Find(n1) );
            uint32_t root2( Find(n2) );
            // IMPORTANT: DO NOTHING IF ALREADY MERGED
            if( root1 < root2 ) m_vecN[root2].m_Parent = root1;
            else if( root1 > root2 ) m_vecN[root1].m_Parent = root2;
        }
    inline uint32_t EnumerateCC( bool b_verbose )
        {
            // Count and enumerate {S_i} \in S
            std::vector< std::vector<uint32_t> > vec_cc;
            {
                auto start = std::chrono::system_clock::now();
                const uint32_t num_nodes( m_vecN.size() );
                std::vector<uint32_t> vec_cc_id( num_nodes, 0 );
                for( uint32_t it_n=0; it_n<num_nodes; it_n++ )
                {
                    uint32_t root( Find( it_n ) );
                    if( it_n == root )
                    {
                        vec_cc_id[it_n] = vec_cc.size();
                        vec_cc.push_back( std::vector<uint32_t>() );
                    }
                    //\todo REQUIRES root<=it_n so that root CC is GUARANTEED to be available
                    vec_cc[ vec_cc_id[root] ].push_back( it_n );
                }
                auto end = std::chrono::system_clock::now();
                std::chrono::duration<float> elapsed = end-start;
                printf( "Enumerate CC = %d in %f sec \n", (int)vec_cc.size(), elapsed.count() );
            }

            if( b_verbose )
            {
                for( uint32_t it_cc=0; it_cc<vec_cc.size(); it_cc++ )
                {
                    printf( "CC[%d] = %d [", it_cc, (int)vec_cc[it_cc].size() );
                    for( uint32_t it_nicc=0; it_nicc<vec_cc[it_cc].size(); it_nicc++ )
                        printf( " %d", vec_cc[it_cc][it_nicc] );
                    printf( " ]\n" );
                }
            }
            return vec_cc.size();
        }
private:
    struct Entry { uint32_t m_Parent; };
    std::vector<Entry> m_vecN;
};
