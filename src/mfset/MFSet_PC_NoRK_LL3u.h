#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <vector>
#include <chrono>

/* Embedded Next,Last children list on each root.
   \todo Try to SIMPLIFY Merge() code
*/
class MFSet_PC_NoRK_LL3u
{
public:
    MFSet_PC_NoRK_LL3u( uint32_t size ) { m_vecN.resize(size); Init(); }
    ~MFSet_PC_NoRK_LL3u() {}
    inline void Init()
        {
            for( uint32_t it_n=0; it_n<m_vecN.size(); it_n++ )
            {
                m_vecN[it_n].m_Parent = it_n;
                m_vecN[it_n].m_Next = 0xFFFFFFFF;
                m_vecN[it_n].m_Last = 0xFFFFFFFF;
            }
        }
    inline uint32_t Find( uint32_t n )
        {
            if( n != m_vecN[n].m_Parent )
                m_vecN[n].m_Parent = Find( m_vecN[n].m_Parent );
            return m_vecN[n].m_Parent;
        }

    /* Next-Last lists
       r1;
         r1 -> r1.n -> r1.nf ---> r1.l -> X
         |__________________________^
       r2;
         r2 -> r2.n -> r2.nf ---> r2.l -> X
         |__________________________^
       r1 + r2:
         r1 -> r1.n -> r1.nf -----> r1.l -> r2 -> r2.n -> .... -> r2.l -> X
         |_________________________________________________________^

       Merge( r1, r2 )
         r1.l.n = r2
         r1.l = r2.l
       For safety we should:
         r1.l.n = X
         r2.l = X
    */
    inline void Merge( uint32_t n1, uint32_t n2 )
        {
            uint32_t root1( Find(n1) );
            uint32_t root2( Find(n2) );

            // IMPORTANT: Using swap to avoid 2 large branches is
            // SLIGHTLY slower, but keeps code MUCH SHORTER, so we'll
            // do it by now

            // IMPORTANT: DO NOTHING IF ALREADY MERGED
            if( root1 == root2 ) return;
            else if( root2 < root1 ) std::swap(root1,root2);

            m_vecN[root2].m_Parent = root1;

            //\todo THIS must be simpler, I'm sure...
            if( m_vecN[root1].m_Next != 0xFFFFFFFF ) //l1 not empty
            {
                m_vecN[ m_vecN[root1].m_Last ].m_Next = root2;
                if( m_vecN[root2].m_Next != 0xFFFFFFFF ) //l2 not empty
                    m_vecN[root1].m_Last = m_vecN[root2].m_Last;
                else
                    m_vecN[root1].m_Last = root2;
            }
            else if( m_vecN[root2].m_Next != 0xFFFFFFFF ) //l2 not empty
            {
                m_vecN[ root1 ].m_Next = root2;
                m_vecN[ root1 ].m_Last = m_vecN[root2].m_Last;
            }
            else // both empty
            {
                m_vecN[ root1 ].m_Next = root2;
                m_vecN[ root1 ].m_Last = root2;
            }

            /* TEMPORAL: this is for safety, but does not affect result...
            // l2.last becomes final \todo WE COULD REUSE its m_Last for list-length here
            if( m_vecN[root2].m_Last != 0xFFFFFFFF )
            {
            m_vecN[ m_vecN[root2].m_Last ].m_Next = 0xFFFFFFFF;
            m_vecN[ m_vecN[root2].m_Last ].m_Last = 0xFFFFFFFF;
            }
            // l2 becomes internal \todo WE COULD REUSE m_Last for list-length here
            m_vecN[root2].m_Last = 0xFFFFFFFF;
            */
        }
    inline uint32_t EnumerateCC( bool b_verbose )
        {
            if( b_verbose )
            {
                // Count and enumerate {S_i} \in S
                std::vector< std::vector<uint32_t> > vec_cc;
                {
                    auto start = std::chrono::system_clock::now();
                    const uint32_t num_nodes( m_vecN.size() );
                    for( uint32_t it_n=0; it_n<num_nodes; it_n++ )
                    {
                        uint32_t root( Find( it_n ) );
                        if( it_n == root )
                        {
                            vec_cc.push_back( std::vector<uint32_t>() );
                            vec_cc.back().push_back( root );
                            for( uint32_t it_ll=m_vecN[root].m_Next;
                                 it_ll != 0xFFFFFFFF;
                                 it_ll = m_vecN[it_ll].m_Next )
                                vec_cc.back().push_back( it_ll );
                        }
                    }
                    auto end = std::chrono::system_clock::now();
                    std::chrono::duration<float> elapsed = end-start;
                    printf( "Enumerate CC = %d, in %f sec \n",
                            (int)vec_cc.size(), elapsed.count() );
                }
                // print
                for( uint32_t it_cc=0; it_cc<vec_cc.size(); it_cc++ )
                {
                    printf( "CC[%d] = %d [", it_cc, (int)vec_cc[it_cc].size() );
                    for( uint32_t it_nicc=0; it_nicc<vec_cc[it_cc].size(); it_nicc++ )
                        printf( " %d", vec_cc[it_cc][it_nicc] );
                    printf( " ]\n" );
                }
                return vec_cc.size();
            }
            else
            {
                // Count and enumerate {S_i} \in S
                uint32_t sum(0); //\todo To avoid elimiation of code with no side-effects
                std::vector< uint32_t > vec_cc_roots;
                {
                    auto start = std::chrono::system_clock::now();
                    const uint32_t num_nodes( m_vecN.size() );
                    for( uint32_t it_n=0; it_n<num_nodes; it_n++ )
                    {
                        uint32_t root( Find( it_n ) );
                        if( it_n == root )
                        {
                            vec_cc_roots.push_back( root );
                            for( uint32_t it_ll=m_vecN[root].m_Next;
                                 it_ll != 0xFFFFFFFF;
                                 it_ll = m_vecN[it_ll].m_Next )
                                sum += it_ll;
                        }
                    }
                    auto end = std::chrono::system_clock::now();
                    std::chrono::duration<float> elapsed = end-start;
                    printf( "Enumerate CC = %d, in %f sec \n",
                            (int)vec_cc_roots.size(), elapsed.count() );
                    printf( "Sum =  %d\n", sum );
                }
                return vec_cc_roots.size();
            }
        }
private:
    struct Entry { uint32_t m_Parent; uint32_t m_Next; uint32_t m_Last; };
    std::vector<Entry> m_vecN;
};
